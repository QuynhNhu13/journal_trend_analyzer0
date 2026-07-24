import { useCallback, useEffect, useState } from 'react';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { Icon } from '../components/ui/Icon';
import { Spinner } from '../components/ui/Spinner';
import { Modal } from '../components/ui/Modal';
import { EmptyState, ErrorState } from '../components/ui/StateView';
import { Skeleton } from '../components/ui/Skeleton';
import { useToast } from '../components/ui/Toast';
import { strings } from '../constants/strings';
import type { DbDoc, DbField, DbFieldType } from '../types/models';
import {
  deleteDocument,
  functionErrorMessage,
  listCollections,
  queryDocuments,
  upsertDocument,
} from '../services/functionsService';

const FIELD_TYPES: DbFieldType[] = ['string', 'number', 'boolean', 'null', 'timestamp', 'json'];
const PAGE = 25;

interface Editing {
  id: string;
  isNew: boolean;
  fields: DbField[];
}

/** Editor for one field's value; the control depends on the field type. */
function FieldValueInput({
  field,
  onChange,
}: {
  field: DbField;
  onChange: (value: string) => void;
}) {
  const base =
    'w-full rounded-md border border-hairline bg-canvas px-2.5 py-1.5 text-sm text-ink outline-none focus:border-brand focus:bg-card';
  if (field.type === 'null') {
    return <input disabled value="null" className={`${base} italic text-faint`} />;
  }
  if (field.type === 'boolean') {
    return (
      <select value={field.value} onChange={(e) => onChange(e.target.value)} className={base}>
        <option value="true">true</option>
        <option value="false">false</option>
      </select>
    );
  }
  if (field.type === 'json') {
    return (
      <textarea
        value={field.value}
        onChange={(e) => onChange(e.target.value)}
        rows={2}
        className={`${base} font-mono`}
      />
    );
  }
  return (
    <input
      type={field.type === 'number' ? 'number' : 'text'}
      value={field.value}
      onChange={(e) => onChange(e.target.value)}
      className={base}
    />
  );
}

export function DatabasePage() {
  const { showToast } = useToast();

  const [collections, setCollections] = useState<string[]>([]);
  const [colsError, setColsError] = useState<string | null>(null);
  const [colsLoading, setColsLoading] = useState(true);

  const [collection, setCollection] = useState<string | null>(null);
  const [docs, setDocs] = useState<DbDoc[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [docsLoading, setDocsLoading] = useState(false);
  const [docsError, setDocsError] = useState<string | null>(null);

  const [editing, setEditing] = useState<Editing | null>(null);
  const [busy, setBusy] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);

  const loadCollections = useCallback(async () => {
    setColsLoading(true);
    setColsError(null);
    try {
      const result = await listCollections({});
      setCollections(result.collections);
    } catch (err) {
      console.error('[Database] listCollections failed:', err);
      setColsError(functionErrorMessage(err, strings.db.collectionsError));
    } finally {
      setColsLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadCollections();
  }, [loadCollections]);

  const loadDocs = useCallback(async (name: string, next?: string | null) => {
    setDocsLoading(true);
    setDocsError(null);
    try {
      const result = await queryDocuments({ collection: name, pageSize: PAGE, cursor: next ?? null });
      setDocs((prev) => (next ? [...prev, ...result.docs] : result.docs));
      setCursor(result.cursor);
      setHasMore(result.hasMore);
    } catch (err) {
      console.error('[Database] queryDocuments failed:', err);
      setDocsError(functionErrorMessage(err, strings.db.docsError));
    } finally {
      setDocsLoading(false);
    }
  }, []);

  const selectCollection = (name: string) => {
    setCollection(name);
    setEditing(null);
    setDocs([]);
    setCursor(null);
    void loadDocs(name);
  };

  const selectDoc = (doc: DbDoc) => {
    setEditing({ id: doc.id, isNew: false, fields: doc.fields.map((f) => ({ ...f })) });
  };

  const newDoc = () => {
    setEditing({ id: '', isNew: true, fields: [{ key: '', type: 'string', value: '' }] });
  };

  const patchField = (index: number, patch: Partial<DbField>) => {
    setEditing((prev) =>
      prev
        ? { ...prev, fields: prev.fields.map((f, i) => (i === index ? { ...f, ...patch } : f)) }
        : prev,
    );
  };

  const save = async () => {
    if (!collection || !editing) return;
    setBusy(true);
    try {
      await upsertDocument({
        collection,
        id: editing.isNew ? editing.id.trim() || undefined : editing.id,
        fields: editing.fields.filter((f) => f.key.trim()),
      });
      showToast(strings.db.saved);
      setEditing(null);
      await loadDocs(collection);
    } catch (err) {
      showToast(functionErrorMessage(err, strings.db.saveError), 'error');
    } finally {
      setBusy(false);
    }
  };

  const doDelete = async () => {
    if (!collection || !editing || editing.isNew) return;
    setBusy(true);
    try {
      await deleteDocument({ collection, id: editing.id });
      showToast(strings.db.deleted);
      setConfirmDelete(false);
      setEditing(null);
      await loadDocs(collection);
    } catch (err) {
      showToast(functionErrorMessage(err, strings.db.deleteError), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHeader title={strings.pages.database.title} subtitle={strings.pages.database.subtitle} />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-8 sm:py-8">
        <div className="grid gap-4 lg:grid-cols-[210px_260px_1fr]">
          {/* Collections */}
          <Card className="!p-0">
            <div className="flex items-center justify-between border-b border-hairline px-4 py-3">
              <span className="text-xs font-bold uppercase tracking-wide text-muted">
                {strings.db.collectionsTitle}
              </span>
              <button
                type="button"
                onClick={() => void loadCollections()}
                className="text-muted hover:text-brand"
                title={strings.db.reload}
              >
                <Icon name="refresh" className="h-4 w-4" />
              </button>
            </div>
            <div className="p-2">
              {colsLoading ? (
                <div className="space-y-2 p-2">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Skeleton key={i} className="h-7" />
                  ))}
                </div>
              ) : colsError ? (
                <p className="p-3 text-sm text-danger">{colsError}</p>
              ) : (
                collections.map((name) => (
                  <button
                    key={name}
                    type="button"
                    onClick={() => selectCollection(name)}
                    className={`flex w-full items-center gap-2 rounded-md px-3 py-2 text-left text-sm font-semibold transition ${
                      collection === name
                        ? 'bg-brand-soft text-brand'
                        : 'text-body hover:bg-canvas'
                    }`}
                  >
                    <Icon name="database" className="h-4 w-4 shrink-0" />
                    <span className="truncate">{name}</span>
                  </button>
                ))
              )}
            </div>
          </Card>

          {/* Documents */}
          <Card className="!p-0">
            <div className="flex items-center justify-between border-b border-hairline px-4 py-3">
              <span className="truncate text-xs font-bold uppercase tracking-wide text-muted">
                {collection ?? strings.db.collectionsTitle}
              </span>
              {collection ? (
                <button
                  type="button"
                  onClick={newDoc}
                  className="flex items-center gap-1 text-xs font-bold text-brand hover:underline"
                >
                  <Icon name="plus" className="h-4 w-4" />
                  {strings.db.newDoc}
                </button>
              ) : null}
            </div>
            <div className="max-h-[520px] overflow-y-auto p-2">
              {!collection ? (
                <p className="p-4 text-sm text-muted">{strings.db.selectCollection}</p>
              ) : docsLoading && docs.length === 0 ? (
                <div className="space-y-2 p-2">
                  {Array.from({ length: 6 }).map((_, i) => (
                    <Skeleton key={i} className="h-7" />
                  ))}
                </div>
              ) : docsError ? (
                <p className="p-3 text-sm text-danger">{docsError}</p>
              ) : docs.length === 0 ? (
                <p className="p-4 text-sm text-muted">{strings.db.docsEmpty}</p>
              ) : (
                <>
                  {docs.map((doc) => (
                    <button
                      key={doc.id}
                      type="button"
                      onClick={() => selectDoc(doc)}
                      className={`block w-full truncate rounded-md px-3 py-2 text-left font-mono text-xs transition ${
                        editing && !editing.isNew && editing.id === doc.id
                          ? 'bg-brand-soft text-brand'
                          : 'text-body hover:bg-canvas'
                      }`}
                    >
                      {doc.id}
                    </button>
                  ))}
                  {hasMore ? (
                    <button
                      type="button"
                      onClick={() => collection && void loadDocs(collection, cursor)}
                      disabled={docsLoading}
                      className="mt-1 w-full rounded-md border border-hairline px-3 py-1.5 text-xs font-semibold text-body hover:border-brand hover:text-brand disabled:opacity-60"
                    >
                      {strings.db.loadMore}
                    </button>
                  ) : null}
                </>
              )}
            </div>
          </Card>

          {/* Editor */}
          <Card>
            {!editing ? (
              <EmptyState icon="database" title={strings.db.selectDoc} />
            ) : (
              <div>
                {collection === 'admins' ? (
                  <div className="mb-4 flex items-start gap-2 rounded-md bg-amber/10 px-3 py-2.5 text-sm text-body">
                    <Icon name="alert" className="mt-0.5 h-4 w-4 shrink-0 text-amber" />
                    {strings.db.adminsWarning}
                  </div>
                ) : null}

                <label className="mb-1 block text-xs font-bold text-muted">
                  {strings.db.docId}
                </label>
                <input
                  value={editing.id}
                  disabled={!editing.isNew}
                  placeholder={strings.db.autoId}
                  onChange={(e) => setEditing({ ...editing, id: e.target.value })}
                  className="mb-4 w-full rounded-md border border-hairline bg-canvas px-3 py-2 font-mono text-sm text-ink outline-none focus:border-brand focus:bg-card disabled:opacity-70"
                />

                <div className="mb-2 flex items-center justify-between">
                  <span className="text-xs font-bold uppercase tracking-wide text-muted">
                    {strings.db.fields}
                  </span>
                  <button
                    type="button"
                    onClick={() =>
                      setEditing({
                        ...editing,
                        fields: [...editing.fields, { key: '', type: 'string', value: '' }],
                      })
                    }
                    className="flex items-center gap-1 text-xs font-bold text-brand hover:underline"
                  >
                    <Icon name="plus" className="h-4 w-4" />
                    {strings.db.addField}
                  </button>
                </div>

                <div className="space-y-2">
                  {editing.fields.map((field, i) => (
                    <div key={i} className="flex items-start gap-2">
                      <input
                        value={field.key}
                        onChange={(e) => patchField(i, { key: e.target.value })}
                        placeholder={strings.db.fieldKey}
                        className="w-32 shrink-0 rounded-md border border-hairline bg-canvas px-2.5 py-1.5 font-mono text-sm text-ink outline-none focus:border-brand focus:bg-card"
                      />
                      <select
                        value={field.type}
                        onChange={(e) =>
                          patchField(i, { type: e.target.value as DbFieldType })
                        }
                        className="w-28 shrink-0 rounded-md border border-hairline bg-card px-2 py-1.5 text-sm font-semibold text-ink outline-none focus:border-brand"
                      >
                        {FIELD_TYPES.map((t) => (
                          <option key={t} value={t}>
                            {t}
                          </option>
                        ))}
                      </select>
                      <div className="flex-1">
                        <FieldValueInput field={field} onChange={(v) => patchField(i, { value: v })} />
                      </div>
                      <button
                        type="button"
                        onClick={() =>
                          setEditing({
                            ...editing,
                            fields: editing.fields.filter((_, fi) => fi !== i),
                          })
                        }
                        className="mt-1 grid h-8 w-8 shrink-0 place-items-center rounded-md text-muted hover:bg-danger/10 hover:text-danger"
                      >
                        <Icon name="close" className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </div>

                <div className="mt-6 flex items-center justify-between">
                  {!editing.isNew ? (
                    <button
                      type="button"
                      onClick={() => setConfirmDelete(true)}
                      className="flex items-center gap-2 rounded-md border border-danger/40 px-3 py-2 text-sm font-semibold text-danger transition hover:bg-danger/5"
                    >
                      <Icon name="trash" className="h-4 w-4" />
                      {strings.db.deleteDoc}
                    </button>
                  ) : (
                    <span />
                  )}
                  <button
                    type="button"
                    onClick={() => void save()}
                    disabled={busy}
                    className="flex items-center gap-2 rounded-md bg-brand px-4 py-2 text-sm font-bold text-white transition hover:bg-brand-bright disabled:opacity-60"
                  >
                    {busy ? <Spinner size={16} className="border-white" /> : <Icon name="check" className="h-[18px] w-[18px]" />}
                    {strings.db.save}
                  </button>
                </div>
              </div>
            )}
          </Card>
        </div>

        {colsError ? (
          <div className="mt-4">
            <ErrorState message={colsError ?? strings.db.collectionsError} onRetry={() => void loadCollections()} />
          </div>
        ) : null}
      </div>

      {confirmDelete && editing && !editing.isNew ? (
        <Modal
          title={strings.db.deleteTitle}
          onClose={() => (busy ? undefined : setConfirmDelete(false))}
          footer={
            <>
              <button
                type="button"
                onClick={() => setConfirmDelete(false)}
                disabled={busy}
                className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas disabled:opacity-60"
              >
                {strings.common.cancel}
              </button>
              <button
                type="button"
                onClick={() => void doDelete()}
                disabled={busy}
                className="flex items-center gap-2 rounded-md bg-danger px-4 py-2 text-sm font-bold text-white transition hover:bg-danger/90 disabled:opacity-60"
              >
                {busy ? <Spinner size={16} className="border-white" /> : null}
                {strings.common.delete}
              </button>
            </>
          }
        >
          <p className="text-sm text-body">
            {strings.db.deleteBody(`${collection}/${editing.id}`)}
          </p>
        </Modal>
      ) : null}
    </div>
  );
}
