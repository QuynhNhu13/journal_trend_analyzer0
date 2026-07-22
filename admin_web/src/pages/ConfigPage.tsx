import { useCallback, useEffect, useMemo, useState } from 'react';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { SectionTitle } from '../components/ui/SectionTitle';
import { Icon } from '../components/ui/Icon';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';
import { Spinner } from '../components/ui/Spinner';
import { TableSkeleton } from '../components/ui/Skeleton';
import { EmptyState, ErrorState } from '../components/ui/StateView';
import { useToast } from '../components/ui/Toast';
import { strings } from '../constants/strings';
import { formatDateTime } from '../lib/format';
import type { RcChange, RcParam, RcTemplateView, RcValueType } from '../types/models';
import {
  functionErrorMessage,
  getRemoteConfigTemplate,
  publishRemoteConfig,
} from '../services/functionsService';

interface NewParam {
  name: string;
  valueType: RcValueType;
  value: string;
  description: string;
}

/** Value editor whose control depends on the parameter type. */
function ValueEditor({
  valueType,
  value,
  disabled,
  onChange,
}: {
  valueType: RcValueType;
  value: string;
  disabled?: boolean;
  onChange: (v: string) => void;
}) {
  const base =
    'w-full rounded-md border border-hairline bg-canvas px-3 py-2 text-sm text-ink outline-none focus:border-brand focus:bg-card disabled:opacity-50';
  if (valueType === 'BOOLEAN') {
    return (
      <select value={value} disabled={disabled} onChange={(e) => onChange(e.target.value)} className={base}>
        <option value="true">true</option>
        <option value="false">false</option>
      </select>
    );
  }
  return (
    <input
      type={valueType === 'NUMBER' ? 'number' : 'text'}
      value={value}
      disabled={disabled}
      onChange={(e) => onChange(e.target.value)}
      className={base}
    />
  );
}

export function ConfigPage() {
  const { showToast } = useToast();

  const [template, setTemplate] = useState<RcTemplateView | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  const [values, setValues] = useState<Record<string, string>>({});
  const [deleted, setDeleted] = useState<Set<string>>(new Set());
  const [added, setAdded] = useState<NewParam[]>([]);

  const [addOpen, setAddOpen] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [publishing, setPublishing] = useState(false);

  const applyTemplate = useCallback((view: RcTemplateView) => {
    setTemplate(view);
    setValues(Object.fromEntries(view.parameters.map((p) => [p.name, p.value ?? ''])));
    setDeleted(new Set());
    setAdded([]);
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      applyTemplate(await getRemoteConfigTemplate({}));
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, [applyTemplate]);

  useEffect(() => {
    void load();
  }, [load]);

  const params = template?.parameters ?? [];

  const changes = useMemo<RcChange[]>(() => {
    const out: RcChange[] = [];
    for (const p of params) {
      if (deleted.has(p.name)) {
        out.push({ op: 'delete', name: p.name });
        continue;
      }
      const current = values[p.name] ?? p.value ?? '';
      if (current !== (p.value ?? '')) {
        out.push({
          op: 'set',
          name: p.name,
          valueType: p.valueType,
          value: current,
          description: p.description,
        });
      }
    }
    for (const a of added) {
      out.push({
        op: 'set',
        name: a.name,
        valueType: a.valueType,
        value: a.value,
        description: a.description,
      });
    }
    return out;
  }, [params, values, deleted, added]);

  const handlePublish = async () => {
    setPublishing(true);
    try {
      applyTemplate(await publishRemoteConfig({ changes }));
      showToast(strings.config.publishedToast);
      setConfirmOpen(false);
    } catch (err) {
      showToast(functionErrorMessage(err, strings.config.publishError), 'error');
    } finally {
      setPublishing(false);
    }
  };

  const toggleDelete = (name: string) => {
    setDeleted((prev) => {
      const next = new Set(prev);
      if (next.has(name)) next.delete(name);
      else next.add(name);
      return next;
    });
  };

  return (
    <div>
      <PageHeader
        title={strings.pages.config.title}
        subtitle={strings.pages.config.subtitle}
      />

      <div className="mx-auto max-w-6xl space-y-6 px-4 py-6 sm:px-8 sm:py-8">
        {/* Meta + actions */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="text-sm text-muted">
            {template?.version?.updateTime ? (
              <>
                {strings.config.lastPublish}:{' '}
                <span className="font-semibold text-ink">
                  {formatDateTime(new Date(template.version.updateTime))}
                </span>
                {template.version.updateUserEmail
                  ? ` ${strings.config.by} ${template.version.updateUserEmail}`
                  : ''}
              </>
            ) : (
              strings.config.never
            )}
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => void load()}
              className="flex items-center gap-2 rounded-md border border-hairline px-3 py-2 text-sm font-semibold text-body transition hover:border-brand hover:text-brand"
            >
              <Icon name="refresh" className="h-4 w-4" />
              {strings.config.reload}
            </button>
            <button
              type="button"
              onClick={() => setAddOpen(true)}
              className="flex items-center gap-2 rounded-md border border-hairline px-3 py-2 text-sm font-semibold text-body transition hover:border-brand hover:text-brand"
            >
              <Icon name="plus" className="h-4 w-4" />
              {strings.config.addButton}
            </button>
          </div>
        </div>

        <div className="flex items-start gap-2 rounded-md bg-brand-soft/60 px-4 py-3 text-sm text-body">
          <Icon name="alert" className="mt-0.5 h-4 w-4 shrink-0 text-brand" />
          {strings.config.effectNote}
        </div>

        <Card className="!p-0">
          <div className="border-b border-hairline p-4">
            <SectionTitle icon="sliders" title={strings.config.tableTitle} />
          </div>

          {loading ? (
            <TableSkeleton rows={4} columns={4} />
          ) : error ? (
            <ErrorState message={strings.config.loadError} onRetry={() => void load()} />
          ) : params.length === 0 && added.length === 0 ? (
            <EmptyState
              icon="sliders"
              title={strings.config.emptyTitle}
              message={strings.config.emptyMessage}
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[760px] border-collapse text-left">
                <thead>
                  <tr className="border-b border-hairline text-xs font-bold uppercase tracking-wide text-muted">
                    <th className="px-4 py-3">{strings.config.col.name}</th>
                    <th className="px-4 py-3">{strings.config.col.type}</th>
                    <th className="w-56 px-4 py-3">{strings.config.col.value}</th>
                    <th className="px-4 py-3">{strings.config.col.description}</th>
                    <th className="px-4 py-3" />
                  </tr>
                </thead>
                <tbody className="divide-y divide-hairline">
                  {params.map((p) => {
                    const isDeleted = deleted.has(p.name);
                    return (
                      <tr key={p.name} className={isDeleted ? 'bg-danger/5' : ''}>
                        <td className="px-4 py-3">
                          <span
                            className={`font-mono text-sm font-semibold ${
                              isDeleted ? 'text-faint line-through' : 'text-ink'
                            }`}
                          >
                            {p.name}
                          </span>
                          {isDeleted ? (
                            <p className="text-xs text-danger">{strings.config.markedDelete}</p>
                          ) : null}
                        </td>
                        <td className="px-4 py-3">
                          <Badge tone="neutral">{p.valueType}</Badge>
                        </td>
                        <td className="px-4 py-3">
                          <ValueEditor
                            valueType={p.valueType}
                            value={values[p.name] ?? ''}
                            disabled={isDeleted}
                            onChange={(v) => setValues((prev) => ({ ...prev, [p.name]: v }))}
                          />
                        </td>
                        <td className="px-4 py-3 text-sm text-muted">{p.description || '—'}</td>
                        <td className="px-4 py-3 text-right">
                          <button
                            type="button"
                            onClick={() => toggleDelete(p.name)}
                            title={isDeleted ? strings.common.cancel : strings.common.delete}
                            className={`grid h-8 w-8 place-items-center rounded-md ${
                              isDeleted
                                ? 'text-muted hover:bg-canvas'
                                : 'text-muted hover:bg-danger/10 hover:text-danger'
                            }`}
                          >
                            <Icon name={isDeleted ? 'refresh' : 'trash'} className="h-[18px] w-[18px]" />
                          </button>
                        </td>
                      </tr>
                    );
                  })}

                  {/* Newly added (unsaved) params */}
                  {added.map((a, i) => (
                    <tr key={`new-${a.name}`} className="bg-emerald/5">
                      <td className="px-4 py-3">
                        <span className="font-mono text-sm font-semibold text-ink">{a.name}</span>
                        <p className="text-xs text-emerald">{strings.config.added}</p>
                      </td>
                      <td className="px-4 py-3">
                        <Badge tone="emerald">{a.valueType}</Badge>
                      </td>
                      <td className="px-4 py-3">
                        <ValueEditor
                          valueType={a.valueType}
                          value={a.value}
                          onChange={(v) =>
                            setAdded((prev) => prev.map((x, xi) => (xi === i ? { ...x, value: v } : x)))
                          }
                        />
                      </td>
                      <td className="px-4 py-3 text-sm text-muted">{a.description || '—'}</td>
                      <td className="px-4 py-3 text-right">
                        <button
                          type="button"
                          onClick={() => setAdded((prev) => prev.filter((_, xi) => xi !== i))}
                          className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-danger/10 hover:text-danger"
                        >
                          <Icon name="trash" className="h-[18px] w-[18px]" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Publish bar */}
          <div className="flex items-center justify-between gap-3 border-t border-hairline p-4">
            <span className="text-xs font-semibold text-muted">
              {changes.length > 0 ? strings.config.pendingCount(changes.length) : strings.config.noChanges}
            </span>
            <button
              type="button"
              onClick={() => setConfirmOpen(true)}
              disabled={changes.length === 0}
              className="flex items-center gap-2 rounded-md bg-brand px-4 py-2 text-sm font-bold text-white transition hover:bg-brand-bright disabled:opacity-50"
            >
              <Icon name="check" className="h-[18px] w-[18px]" />
              {strings.config.publishButton}
            </button>
          </div>
        </Card>
      </div>

      {addOpen ? (
        <AddParamModal
          existingNames={[...params.map((p) => p.name), ...added.map((a) => a.name)]}
          onClose={() => setAddOpen(false)}
          onAdd={(param) => {
            setAdded((prev) => [...prev, param]);
            setAddOpen(false);
          }}
        />
      ) : null}

      {confirmOpen ? (
        <PublishConfirmModal
          params={params}
          changes={changes}
          publishing={publishing}
          onClose={() => (publishing ? undefined : setConfirmOpen(false))}
          onConfirm={() => void handlePublish()}
        />
      ) : null}
    </div>
  );
}

// ── Add parameter modal ──
function AddParamModal({
  existingNames,
  onClose,
  onAdd,
}: {
  existingNames: string[];
  onClose: () => void;
  onAdd: (param: NewParam) => void;
}) {
  const [name, setName] = useState('');
  const [valueType, setValueType] = useState<RcValueType>('STRING');
  const [value, setValue] = useState('');
  const [description, setDescription] = useState('');
  const [err, setErr] = useState<string | null>(null);

  const submit = () => {
    const trimmed = name.trim();
    if (!/^[A-Za-z0-9_]+$/.test(trimmed)) {
      setErr(strings.config.invalidName);
      return;
    }
    if (existingNames.includes(trimmed)) {
      setErr(strings.config.duplicateName);
      return;
    }
    const finalValue = valueType === 'BOOLEAN' && !value ? 'false' : value;
    onAdd({ name: trimmed, valueType, value: finalValue, description: description.trim() });
  };

  return (
    <Modal
      title={strings.config.newTitle}
      onClose={onClose}
      footer={
        <>
          <button
            type="button"
            onClick={onClose}
            className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas"
          >
            {strings.common.cancel}
          </button>
          <button
            type="button"
            onClick={submit}
            className="rounded-md bg-brand px-4 py-2 text-sm font-bold text-white transition hover:bg-brand-bright"
          >
            {strings.config.add}
          </button>
        </>
      }
    >
      <div className="space-y-4">
        <div>
          <label className="mb-1 block text-xs font-bold text-muted">{strings.config.fieldName}</label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full rounded-md border border-hairline bg-canvas px-3 py-2 font-mono text-sm text-ink outline-none focus:border-brand focus:bg-card"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-bold text-muted">{strings.config.fieldType}</label>
          <select
            value={valueType}
            onChange={(e) => setValueType(e.target.value as RcValueType)}
            className="w-full rounded-md border border-hairline bg-card px-3 py-2 text-sm font-semibold text-ink outline-none focus:border-brand"
          >
            <option value="NUMBER">{strings.config.typeNumber}</option>
            <option value="STRING">{strings.config.typeString}</option>
            <option value="BOOLEAN">{strings.config.typeBoolean}</option>
          </select>
        </div>
        <div>
          <label className="mb-1 block text-xs font-bold text-muted">{strings.config.fieldValue}</label>
          <ValueEditor valueType={valueType} value={value} onChange={setValue} />
        </div>
        <div>
          <label className="mb-1 block text-xs font-bold text-muted">
            {strings.config.fieldDescription}
          </label>
          <input
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full rounded-md border border-hairline bg-canvas px-3 py-2 text-sm text-ink outline-none focus:border-brand focus:bg-card"
          />
        </div>
        {err ? <p className="text-sm text-danger">{err}</p> : null}
      </div>
    </Modal>
  );
}

// ── Publish confirmation with before → after diff ──
function PublishConfirmModal({
  params,
  changes,
  publishing,
  onClose,
  onConfirm,
}: {
  params: RcParam[];
  changes: RcChange[];
  publishing: boolean;
  onClose: () => void;
  onConfirm: () => void;
}) {
  const before = new Map(params.map((p) => [p.name, p.value ?? '']));

  return (
    <Modal
      title={strings.config.confirmTitle}
      size="lg"
      onClose={onClose}
      footer={
        <>
          <button
            type="button"
            onClick={onClose}
            disabled={publishing}
            className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas disabled:opacity-60"
          >
            {strings.common.cancel}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={publishing}
            className="flex items-center gap-2 rounded-md bg-brand px-4 py-2 text-sm font-bold text-white transition hover:bg-brand-bright disabled:opacity-60"
          >
            {publishing ? <Spinner size={16} className="border-white" /> : null}
            {publishing ? strings.config.publishing : strings.config.publishButton}
          </button>
        </>
      }
    >
      <p className="mb-4 text-sm text-muted">{strings.config.confirmIntro}</p>
      <ul className="space-y-2">
        {changes.map((c) => {
          const tag =
            c.op === 'delete'
              ? strings.config.removed
              : before.has(c.name)
                ? strings.config.changed
                : strings.config.added;
          const beforeVal = before.get(c.name) ?? '—';
          const afterVal = c.op === 'delete' ? '—' : c.value;
          return (
            <li key={`${c.op}-${c.name}`} className="rounded-md border border-hairline p-3">
              <div className="flex items-center gap-2">
                <Badge tone={c.op === 'delete' ? 'neutral' : 'brand'}>{tag}</Badge>
                <span className="font-mono text-sm font-semibold text-ink">{c.name}</span>
              </div>
              <div className="mt-2 flex items-center gap-2 text-sm">
                <span className="rounded bg-canvas px-2 py-0.5 font-mono text-muted line-through">
                  {beforeVal || '—'}
                </span>
                <Icon name="chevronRight" className="h-4 w-4 text-faint" />
                <span className="rounded bg-brand-soft px-2 py-0.5 font-mono font-semibold text-brand">
                  {afterVal || '—'}
                </span>
              </div>
            </li>
          );
        })}
      </ul>
    </Modal>
  );
}
