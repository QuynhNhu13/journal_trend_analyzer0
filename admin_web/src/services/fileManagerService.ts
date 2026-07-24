import { collection, deleteDoc, getDocs, query, where } from 'firebase/firestore';
import {
  deleteObject,
  getBytes,
  getDownloadURL,
  getMetadata,
  listAll,
  ref,
  uploadBytes,
  uploadBytesResumable,
} from 'firebase/storage';

import { db, storage } from '../lib/firebase';

/**
 * Base folder for the Storage manager. The app's exported PDFs live in
 * `reports/`, and the Storage rules grant list/read there — so we anchor here
 * (listing the true bucket root is not granted by the recursive-wildcard rule
 * and would only show a `reports` folder anyway).
 */
export const ROOT_PATH = 'reports/';

export const MAX_FILE_BYTES = 10 * 1024 * 1024; // 10 MB
export const ACCEPTED_TYPES = ['application/pdf', 'image/png', 'image/jpeg'];

/** Placeholder object used to make an "empty" folder appear in listings. */
const KEEP_FILE = '.keep';

export interface StorageFile {
  name: string;
  fullPath: string;
  sizeBytes: number;
  contentType: string | null;
  updated: Date | null;
  downloadUrl: string;
}

export interface StorageFolder {
  name: string;
  /** Full path WITH trailing slash, ready to become the next currentPath. */
  path: string;
}

export interface FolderListing {
  folders: StorageFolder[];
  files: StorageFile[];
  totalBytes: number;
}

/** Lists one folder: subfolders + files (with size, type, modified, URL). */
export async function listFolder(path: string): Promise<FolderListing> {
  const result = await listAll(ref(storage, path));

  const folders: StorageFolder[] = result.prefixes.map((p) => ({
    name: p.name,
    path: `${p.fullPath}/`,
  }));

  const files: StorageFile[] = await Promise.all(
    result.items
      .filter((item) => item.name !== KEEP_FILE)
      .map(async (item) => {
        const [meta, url] = await Promise.all([getMetadata(item), getDownloadURL(item)]);
        return {
          name: item.name,
          fullPath: item.fullPath,
          sizeBytes: meta.size,
          contentType: meta.contentType ?? null,
          updated: meta.updated ? new Date(meta.updated) : null,
          downloadUrl: url,
        };
      }),
  );

  files.sort((a, b) => a.name.localeCompare(b.name));
  folders.sort((a, b) => a.name.localeCompare(b.name));
  const totalBytes = files.reduce((sum, f) => sum + f.sizeBytes, 0);

  return { folders, files, totalBytes };
}

/** Returns a validation error key, or null when the file is acceptable. */
export function validateFile(file: File): 'unsupported' | 'too-large' | null {
  if (!ACCEPTED_TYPES.includes(file.type)) return 'unsupported';
  if (file.size > MAX_FILE_BYTES) return 'too-large';
  return null;
}

/** Uploads a file into `path`, reporting 0–100 progress. */
export function uploadFile(
  path: string,
  file: File,
  onProgress: (percent: number) => void,
): Promise<void> {
  return new Promise((resolve, reject) => {
    const task = uploadBytesResumable(ref(storage, `${path}${file.name}`), file, {
      contentType: file.type,
    });
    task.on(
      'state_changed',
      (snapshot) =>
        onProgress(Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100)),
      reject,
      () => resolve(),
    );
  });
}

/** Deletes a Storage object and any matching `reports` documents (by fileName). */
export async function deleteFile(file: StorageFile): Promise<void> {
  await deleteObject(ref(storage, file.fullPath));
  const snapshot = await getDocs(
    query(collection(db, 'reports'), where('fileName', '==', file.name)),
  );
  await Promise.all(snapshot.docs.map((d) => deleteDoc(d.ref)));
}

/** Deletes several files (used by multi-select). */
export async function deleteFiles(files: StorageFile[]): Promise<void> {
  for (const file of files) {
    await deleteFile(file);
  }
}

/** Renames a file by copying its bytes to a new name, then deleting the old. */
export async function renameFile(
  file: StorageFile,
  newName: string,
  currentPath: string,
): Promise<void> {
  const bytes = await getBytes(ref(storage, file.fullPath));
  await uploadBytes(ref(storage, `${currentPath}${newName}`), bytes, {
    contentType: file.contentType ?? undefined,
  });
  await deleteObject(ref(storage, file.fullPath));
}

/** Creates a folder by writing a hidden placeholder object inside it. */
export async function createFolder(currentPath: string, name: string): Promise<void> {
  await uploadBytes(ref(storage, `${currentPath}${name}/${KEEP_FILE}`), new Uint8Array(0));
}
