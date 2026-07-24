import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { StatCard } from '../components/ui/StatCard';
import { Icon } from '../components/ui/Icon';
import { Modal } from '../components/ui/Modal';
import { Spinner } from '../components/ui/Spinner';
import { TableSkeleton } from '../components/ui/Skeleton';
import { RowActions } from '../components/ui/RowActions';
import { Pagination, usePagination } from '../components/ui/Pagination';
import { EmptyState, ErrorState } from '../components/ui/StateView';
import { useToast } from '../components/ui/Toast';
import { functionErrorMessage } from '../services/functionsService';
import { strings } from '../constants/strings';
import { formatBytes, formatDateTime } from '../lib/format';
import {
  ROOT_PATH,
  createFolder,
  deleteFile,
  deleteFiles,
  listFolder,
  uploadFile,
  validateFile,
  type FolderListing,
  type StorageFile,
} from '../services/fileManagerService';

function typeLabel(contentType: string | null): string {
  if (!contentType) return '—';
  if (contentType.includes('pdf')) return 'PDF';
  if (contentType.includes('png')) return 'PNG';
  if (contentType.includes('jpeg') || contentType.includes('jpg')) return 'JPG';
  return contentType;
}

interface Crumb {
  label: string;
  path: string;
}

function crumbsFor(path: string): Crumb[] {
  // Breadcrumb is anchored at ROOT_PATH so navigation never goes above it.
  const crumbs: Crumb[] = [{ label: strings.files.root, path: ROOT_PATH }];
  const rel = path.startsWith(ROOT_PATH) ? path.slice(ROOT_PATH.length) : path;
  let acc = ROOT_PATH;
  for (const part of rel.split('/').filter(Boolean)) {
    acc += `${part}/`;
    crumbs.push({ label: part, path: acc });
  }
  return crumbs;
}

type Dialog =
  | { kind: 'delete-one'; file: StorageFile }
  | { kind: 'delete-many' }
  | { kind: 'new-folder' }
  | null;

export function StoragePage() {
  const { showToast } = useToast();
  const fileInput = useRef<HTMLInputElement>(null);

  const [path, setPath] = useState(ROOT_PATH);
  const [listing, setListing] = useState<FolderListing | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [uploading, setUploading] = useState<{ name: string; percent: number } | null>(null);
  const [dragging, setDragging] = useState(false);

  const [dialog, setDialog] = useState<Dialog>(null);
  const [busy, setBusy] = useState(false);
  const [folderValue, setFolderValue] = useState('');

  const load = useCallback(async (target: string) => {
    setLoading(true);
    setError(null);
    setSelected(new Set());
    try {
      setListing(await listFolder(target));
    } catch (err) {
      console.error('[Storage] listFolder failed:', err);
      setError(functionErrorMessage(err, strings.files.errorMessage));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load(path);
  }, [load, path]);

  const files = useMemo(() => {
    const raw = listing?.files ?? [];
    return [...raw].sort((a, b) => {
      const ta = a.updated?.getTime() ?? 0;
      const tb = b.updated?.getTime() ?? 0;
      return tb - ta;
    });
  }, [listing]);
  const folders = listing?.folders ?? [];

  const selectedFiles = useMemo(
    () => files.filter((f) => selected.has(f.fullPath)),
    [files, selected],
  );

  const toggle = (fullPath: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(fullPath)) next.delete(fullPath);
      else next.add(fullPath);
      return next;
    });
  };

  // Folders stay pinned at the top as navigation; only files are paginated.
  const filesPager = usePagination(files, 15);

  const allChecked = files.length > 0 && selected.size === files.length;
  const toggleAll = () => {
    setSelected(allChecked ? new Set() : new Set(files.map((f) => f.fullPath)));
  };

  const handleFiles = async (list: FileList | null) => {
    if (!list || list.length === 0) return;
    const chosen = Array.from(list);
    const invalidType = chosen.find((f) => validateFile(f) === 'unsupported');
    if (invalidType) {
      showToast(strings.files.rejectedType, 'error');
      return;
    }
    const invalidSize = chosen.find((f) => validateFile(f) === 'too-large');
    if (invalidSize) {
      showToast(strings.files.rejectedSize, 'error');
      return;
    }
    try {
      for (const file of chosen) {
        setUploading({ name: file.name, percent: 0 });
        await uploadFile(path, file, (percent) => setUploading({ name: file.name, percent }));
      }
      showToast(strings.files.uploadedToast);
      await load(path);
    } catch {
      showToast(strings.files.uploadError, 'error');
    } finally {
      setUploading(null);
      if (fileInput.current) fileInput.current.value = '';
    }
  };

  const closeDialog = () => {
    if (busy) return;
    setDialog(null);
    setFolderValue('');
  };

  const copyLink = async (url: string) => {
    try {
      await navigator.clipboard.writeText(url);
      showToast(strings.common.copied);
    } catch {
      showToast(strings.files.deleteError, 'error');
    }
  };

  const runDeleteOne = async (file: StorageFile) => {
    setBusy(true);
    try {
      await deleteFile(file);
      showToast(strings.files.deletedToast);
      setDialog(null);
      await load(path);
    } catch {
      showToast(strings.files.deleteError, 'error');
    } finally {
      setBusy(false);
    }
  };

  const runDeleteMany = async () => {
    setBusy(true);
    try {
      await deleteFiles(selectedFiles);
      showToast(strings.files.deletedToast);
      setDialog(null);
      await load(path);
    } catch {
      showToast(strings.files.deleteError, 'error');
    } finally {
      setBusy(false);
    }
  };

  const runCreateFolder = async () => {
    const name = folderValue.trim();
    if (!/^[A-Za-z0-9_-]+$/.test(name)) {
      showToast(strings.files.invalidFolder, 'error');
      return;
    }
    setBusy(true);
    try {
      await createFolder(path, name);
      showToast(strings.files.folderCreatedToast);
      setDialog(null);
      setFolderValue('');
      await load(path);
    } catch {
      showToast(strings.files.folderError, 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHeader title={strings.pages.storage.title} subtitle={strings.pages.storage.subtitle} />

      <div className="mx-auto max-w-6xl space-y-6 px-4 py-6 sm:px-8 sm:py-8">
        <div className="grid gap-4 sm:grid-cols-2">
          <StatCard icon="file" label={strings.overview.kpiReports} value={files.length} />
          <StatCard
            icon="inbox"
            label={strings.files.totalUsed}
            value={listing ? formatBytes(listing.totalBytes) : '—'}
          />
        </div>

        <Card className="!p-0">
          {/* Toolbar: breadcrumb + actions */}
          <div className="flex flex-col gap-3 border-b border-hairline p-4 lg:flex-row lg:items-center lg:justify-between">
            <nav className="flex flex-wrap items-center gap-1 text-sm">
              {crumbsFor(path).map((c, i, arr) => (
                <span key={c.path} className="flex items-center gap-1">
                  {i === 0 ? <Icon name="home" className="h-4 w-4 text-faint" /> : null}
                  <button
                    type="button"
                    onClick={() => setPath(c.path)}
                    className={`rounded px-1.5 py-0.5 font-semibold ${
                      i === arr.length - 1 ? 'text-ink' : 'text-muted hover:text-brand'
                    }`}
                  >
                    {c.label}
                  </button>
                  {i < arr.length - 1 ? (
                    <Icon name="chevronRight" className="h-3.5 w-3.5 text-faint" />
                  ) : null}
                </span>
              ))}
            </nav>

            <div className="flex flex-wrap items-center gap-2">
              {selectedFiles.length > 0 ? (
                <button
                  type="button"
                  onClick={() => setDialog({ kind: 'delete-many' })}
                  className="flex items-center gap-2 rounded-md border border-danger/40 px-3 py-2 text-sm font-semibold text-danger transition hover:bg-danger/5"
                >
                  <Icon name="trash" className="h-4 w-4" />
                  {strings.files.deleteSelected} ({selectedFiles.length})
                </button>
              ) : null}
              <button
                type="button"
                onClick={() => setDialog({ kind: 'new-folder' })}
                className="flex items-center gap-2 rounded-md border border-hairline px-3 py-2 text-sm font-semibold text-body transition hover:border-brand hover:text-brand"
              >
                <Icon name="folder" className="h-4 w-4" />
                {strings.files.newFolder}
              </button>
              <button
                type="button"
                onClick={() => fileInput.current?.click()}
                disabled={uploading !== null}
                className="flex items-center gap-2 rounded-md bg-brand px-3 py-2 text-sm font-bold text-white transition hover:bg-brand-bright disabled:opacity-60"
              >
                <Icon name="upload" className="h-4 w-4" />
                {strings.files.upload}
              </button>
              <input
                ref={fileInput}
                type="file"
                multiple
                accept=".pdf,.png,.jpg,.jpeg"
                className="hidden"
                onChange={(e) => void handleFiles(e.target.files)}
              />
            </div>
          </div>

          {/* Upload progress */}
          {uploading ? (
            <div className="border-b border-hairline bg-subtle px-4 py-3">
              <div className="mb-1 flex items-center justify-between text-xs font-semibold text-body">
                <span className="truncate">
                  {strings.files.uploading} {uploading.name}
                </span>
                <span>{uploading.percent}%</span>
              </div>
              <div className="h-1.5 w-full overflow-hidden rounded-full bg-white">
                <div
                  className="h-full rounded-full bg-brand transition-all"
                  style={{ width: `${uploading.percent}%` }}
                />
              </div>
            </div>
          ) : null}

          {/* Dropzone hint */}
          <div
            onDragOver={(e) => {
              e.preventDefault();
              setDragging(true);
            }}
            onDragLeave={() => setDragging(false)}
            onDrop={(e) => {
              e.preventDefault();
              setDragging(false);
              void handleFiles(e.dataTransfer.files);
            }}
            className={`border-b border-hairline px-4 py-2 text-center text-xs ${
              dragging ? 'bg-brand-soft text-brand' : 'text-faint'
            }`}
          >
            {strings.files.dropHint} · {strings.files.acceptHint}
          </div>

          {/* Body */}
          {loading ? (
            <TableSkeleton rows={5} columns={4} />
          ) : error ? (
            <ErrorState message={error} onRetry={() => void load(path)} />
          ) : folders.length === 0 && files.length === 0 ? (
            <EmptyState
              icon="folder"
              title={strings.files.emptyTitle}
              message={strings.files.emptyMessage}
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[760px] border-collapse text-left">
                <thead>
                  <tr className="border-b border-hairline bg-subtle text-label uppercase text-muted">
                    <th className="w-10 px-4 py-3">
                      <input
                        type="checkbox"
                        checked={allChecked}
                        onChange={toggleAll}
                        className="h-4 w-4 accent-brand"
                        aria-label="Select all"
                      />
                    </th>
                    <th className="px-4 py-3">{strings.files.col.name}</th>
                    <th className="px-4 py-3 text-right">{strings.files.col.size}</th>
                    <th className="px-4 py-3">{strings.files.col.type}</th>
                    <th className="px-4 py-3">{strings.files.col.modified}</th>
                    <th className="px-4 py-3 text-right">{strings.files.col.actions}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-hairline">
                  {folders.map((f) => (
                    <tr
                      key={f.path}
                      onClick={() => setPath(f.path)}
                      className="cursor-pointer transition hover:bg-subtle"
                    >
                      <td className="px-4 py-3" />
                      <td className="px-4 py-3" colSpan={5}>
                        <div className="flex items-center gap-2.5">
                          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-md bg-subtle text-muted">
                            <Icon name="folder" className="h-[18px] w-[18px]" />
                          </span>
                          <span className="text-sm font-semibold text-ink">{f.name}</span>
                        </div>
                      </td>
                    </tr>
                  ))}

                  {filesPager.pageItems.map((file) => (
                    <tr key={file.fullPath} className="transition hover:bg-subtle">
                      <td className="px-4 py-3">
                        <input
                          type="checkbox"
                          checked={selected.has(file.fullPath)}
                          onChange={() => toggle(file.fullPath)}
                          className="h-4 w-4 accent-brand"
                          aria-label={`Select ${file.name}`}
                        />
                      </td>
                      <td className="max-w-[240px] px-4 py-3">
                        <div className="flex items-center gap-2.5">
                          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-md bg-subtle text-muted">
                            <Icon name="file" className="h-4 w-4" />
                          </span>
                          <span className="truncate text-sm font-semibold text-ink">
                            {file.name}
                          </span>
                        </div>
                      </td>
                      <td className="tnums whitespace-nowrap px-4 py-3 text-right text-sm text-muted">
                        {formatBytes(file.sizeBytes)}
                      </td>
                      <td className="px-4 py-3 text-sm text-muted">{typeLabel(file.contentType)}</td>
                      <td className="whitespace-nowrap px-4 py-3 text-sm text-muted">
                        {formatDateTime(file.updated)}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center justify-end gap-1">
                          <a
                            href={file.downloadUrl}
                            target="_blank"
                            rel="noreferrer"
                            title={strings.files.open}
                            className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-canvas hover:text-brand"
                          >
                            <Icon name="external" className="h-[18px] w-[18px]" />
                          </a>
                          <a
                            href={file.downloadUrl}
                            download={file.name}
                            title={strings.files.download}
                            className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-canvas hover:text-brand"
                          >
                            <Icon name="download" className="h-[18px] w-[18px]" />
                          </a>
                          <RowActions
                            actions={[
                              {
                                label: strings.files.copy,
                                icon: 'copy',
                                onClick: () => void copyLink(file.downloadUrl),
                              },
                              {
                                label: strings.common.delete,
                                icon: 'trash',
                                danger: true,
                                onClick: () => setDialog({ kind: 'delete-one', file }),
                              },
                            ]}
                          />
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <Pagination
                page={filesPager.page}
                totalPages={filesPager.totalPages}
                total={files.length}
                pageSize={filesPager.pageSize}
                onPageChange={filesPager.setPage}
              />
            </div>
          )}
        </Card>
      </div>

      {/* Dialogs */}
      {dialog?.kind === 'delete-one' ? (
        <ConfirmDialog
          title={strings.files.deleteOneTitle}
          body={strings.files.deleteOneBody(dialog.file.name)}
          confirmLabel={strings.common.delete}
          danger
          busy={busy}
          onCancel={closeDialog}
          onConfirm={() => void runDeleteOne(dialog.file)}
        />
      ) : null}

      {dialog?.kind === 'delete-many' ? (
        <ConfirmDialog
          title={strings.files.deleteManyTitle}
          body={strings.files.deleteManyBody(selectedFiles.length)}
          confirmLabel={strings.common.delete}
          danger
          busy={busy}
          onCancel={closeDialog}
          onConfirm={() => void runDeleteMany()}
        />
      ) : null}

      {dialog?.kind === 'new-folder' ? (
        <Modal
          title={strings.files.newFolderTitle}
          onClose={closeDialog}
          footer={
            <>
              <button
                type="button"
                onClick={closeDialog}
                disabled={busy}
                className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas disabled:opacity-60"
              >
                {strings.common.cancel}
              </button>
              <button
                type="button"
                onClick={() => void runCreateFolder()}
                disabled={busy || !folderValue.trim()}
                className="flex items-center gap-2 rounded-md bg-brand px-4 py-2 text-sm font-bold text-white transition hover:bg-brand-bright disabled:opacity-60"
              >
                {busy ? <Spinner size={16} className="border-white" /> : null}
                {strings.files.create}
              </button>
            </>
          }
        >
          <label className="mb-1 block text-xs font-bold text-muted">
            {strings.files.newFolderLabel}
          </label>
          <input
            type="text"
            value={folderValue}
            onChange={(e) => setFolderValue(e.target.value)}
            className="w-full rounded-md border border-hairline bg-canvas px-3 py-2.5 text-sm text-ink outline-none focus:border-brand focus:bg-card"
          />
        </Modal>
      ) : null}
    </div>
  );
}

// ── Simple confirm dialog ──
function ConfirmDialog({
  title,
  body,
  confirmLabel,
  danger,
  busy,
  onCancel,
  onConfirm,
}: {
  title: string;
  body: string;
  confirmLabel: string;
  danger?: boolean;
  busy: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <Modal
      title={title}
      onClose={onCancel}
      footer={
        <>
          <button
            type="button"
            onClick={onCancel}
            disabled={busy}
            className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas disabled:opacity-60"
          >
            {strings.common.cancel}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={busy}
            className={`flex items-center gap-2 rounded-md px-4 py-2 text-sm font-bold text-white transition disabled:opacity-60 ${
              danger ? 'bg-danger hover:bg-danger/90' : 'bg-brand hover:bg-brand-bright'
            }`}
          >
            {busy ? <Spinner size={16} className="border-white" /> : null}
            {confirmLabel}
          </button>
        </>
      }
    >
      <p className="text-sm text-body">{body}</p>
    </Modal>
  );
}
