import { FieldPath, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { assertAdmin } from './lib/assertAdmin';
import { db, REGION } from './lib/firebase';
import { writeAdminLog } from './lib/logs';
import { wrap } from './lib/wrap';

/** A JSON-safe representation of one document field for the editor UI. */
type FieldType = 'string' | 'number' | 'boolean' | 'null' | 'timestamp' | 'json';
interface SerializedField {
  key: string;
  type: FieldType;
  value: string;
}
interface SerializedDoc {
  id: string;
  fields: SerializedField[];
}

function serializeField(key: string, value: unknown): SerializedField {
  if (value === null || value === undefined) return { key, type: 'null', value: '' };
  if (value instanceof Timestamp) {
    return { key, type: 'timestamp', value: value.toDate().toISOString() };
  }
  switch (typeof value) {
    case 'string':
      return { key, type: 'string', value };
    case 'number':
      return { key, type: 'number', value: String(value) };
    case 'boolean':
      return { key, type: 'boolean', value: String(value) };
    default:
      try {
        return { key, type: 'json', value: JSON.stringify(value) };
      } catch {
        return { key, type: 'string', value: String(value) };
      }
  }
}

function deserializeField(field: SerializedField): unknown {
  switch (field.type) {
    case 'string':
      return field.value;
    case 'number': {
      const n = Number(field.value);
      if (Number.isNaN(n)) {
        throw new HttpsError('invalid-argument', `Field "${field.key}" is not a number.`);
      }
      return n;
    }
    case 'boolean':
      return field.value === 'true';
    case 'null':
      return null;
    case 'timestamp': {
      const date = new Date(field.value);
      if (Number.isNaN(date.getTime())) {
        throw new HttpsError('invalid-argument', `Field "${field.key}" is not a valid date.`);
      }
      return Timestamp.fromDate(date);
    }
    case 'json':
      try {
        return JSON.parse(field.value);
      } catch {
        throw new HttpsError('invalid-argument', `Field "${field.key}" is not valid JSON.`);
      }
    default:
      return field.value;
  }
}

/** Lists top-level collection ids. */
export const listCollections = onCall({ region: REGION }, async (request) => {
  await assertAdmin(request);
  const cols = await wrap('listCollections', () => db.listCollections());
  return { collections: cols.map((c) => c.id).sort() };
});

interface QueryData {
  collection: string;
  pageSize?: number;
  cursor?: string | null;
}

/** Returns one page of documents (ordered by id) with serialized fields. */
export const queryDocuments = onCall<QueryData>({ region: REGION }, async (request) => {
  await assertAdmin(request);
  const { collection, pageSize, cursor } = request.data;
  if (!collection?.trim()) {
    throw new HttpsError('invalid-argument', 'A collection is required.');
  }
  const size = Math.min(Math.max(pageSize ?? 25, 1), 100);

  let q = db.collection(collection).orderBy(FieldPath.documentId()).limit(size);
  if (cursor) q = q.startAfter(cursor);

  const snapshot = await wrap('queryDocuments', () => q.get());
  const docs: SerializedDoc[] = snapshot.docs.map((doc) => ({
    id: doc.id,
    fields: Object.entries(doc.data()).map(([k, v]) => serializeField(k, v)),
  }));
  const lastDoc = snapshot.docs[snapshot.docs.length - 1];

  return {
    docs,
    cursor: lastDoc?.id ?? null,
    hasMore: snapshot.size === size,
  };
});

interface UpsertDocData {
  collection: string;
  id?: string;
  fields: SerializedField[];
}

/** Creates or replaces a document from a list of serialized fields. */
export const upsertDocument = onCall<UpsertDocData>({ region: REGION }, async (request) => {
  const admin = await assertAdmin(request);
  const { collection, id, fields } = request.data;
  if (!collection?.trim()) {
    throw new HttpsError('invalid-argument', 'A collection is required.');
  }

  const data: Record<string, unknown> = {};
  for (const field of fields ?? []) {
    if (!field.key?.trim()) continue;
    data[field.key] = deserializeField(field);
  }

  let docId = id;
  if (docId) {
    await db.collection(collection).doc(docId).set(data);
  } else {
    const created = await db.collection(collection).add(data);
    docId = created.id;
  }

  await writeAdminLog({
    actorEmail: admin.email,
    action: id ? 'updateDocument' : 'createDocument',
    targetId: `${collection}/${docId}`,
    params: { fields: (fields ?? []).map((f) => f.key) },
  });

  return { id: docId };
});

interface DeleteDocData {
  collection: string;
  id: string;
}

/** Deletes a document. Refuses to remove the caller's own admin entry. */
export const deleteDocument = onCall<DeleteDocData>({ region: REGION }, async (request) => {
  const admin = await assertAdmin(request);
  const { collection, id } = request.data;
  if (!collection?.trim() || !id?.trim()) {
    throw new HttpsError('invalid-argument', 'A collection and document id are required.');
  }
  if (collection === 'admins' && id === admin.email) {
    throw new HttpsError(
      'failed-precondition',
      'You cannot remove your own admin access.',
    );
  }

  await writeAdminLog({
    actorEmail: admin.email,
    action: 'deleteDocument',
    targetId: `${collection}/${id}`,
  });
  await db.collection(collection).doc(id).delete();

  return { collection, id };
});
