import type {
  ParameterValueType,
  RemoteConfigParameter,
  RemoteConfigTemplate,
} from 'firebase-admin/remote-config';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { assertAdmin } from './lib/assertAdmin';
import { remoteConfig, REGION } from './lib/firebase';
import { writeAdminLog } from './lib/logs';
import { wrap } from './lib/wrap';

/** A flattened, serializable view of one Remote Config parameter. */
interface RcParam {
  name: string;
  valueType: ParameterValueType;
  /** The default value as a string, or null when it uses the in-app default. */
  value: string | null;
  description: string;
  /** Name of the parameter group this lives in, or null for a top-level param. */
  group: string | null;
}

interface RcTemplateView {
  parameters: RcParam[];
  version: { updateTime: string | null; updateUserEmail: string | null } | null;
}

/** One pending change to apply in a single atomic publish. */
type RcChange =
  | {
      op: 'set';
      name: string;
      valueType: ParameterValueType;
      value: string;
      description?: string;
    }
  | { op: 'delete'; name: string };

interface PublishData {
  changes: RcChange[];
}

/** Flattens one Admin-SDK parameter into the serializable view shape. */
function toParam(
  name: string,
  param: RemoteConfigParameter,
  group: string | null,
): RcParam {
  const def = param.defaultValue;
  const value = def && 'value' in def && typeof def.value === 'string' ? def.value : null;
  return {
    name,
    valueType: param.valueType ?? 'STRING',
    value,
    description: param.description ?? '',
    group,
  };
}

function toView(template: RemoteConfigTemplate): RcTemplateView {
  const parameters: RcParam[] = [];
  // Top-level parameters.
  for (const [name, param] of Object.entries(template.parameters ?? {})) {
    parameters.push(toParam(name, param, null));
  }
  // Parameters nested inside parameter GROUPS (e.g. created via the Firebase
  // Console). These were previously invisible because only template.parameters
  // was read — that is why max_journals_displayed did not appear on the web.
  for (const [groupName, grp] of Object.entries(template.parameterGroups ?? {})) {
    for (const [name, param] of Object.entries(grp.parameters ?? {})) {
      parameters.push(toParam(name, param, groupName));
    }
  }
  parameters.sort((a, b) => a.name.localeCompare(b.name));

  const version = template.version
    ? {
        updateTime: template.version.updateTime ?? null,
        updateUserEmail: template.version.updateUser?.email ?? null,
      }
    : null;

  return { parameters, version };
}

/**
 * Returns the map that should hold `name`: the parameter group's map if the
 * param already lives in a group, otherwise the top-level parameters map (also
 * where brand-new params are created). This keeps Console-grouped params in
 * their group when edited instead of duplicating them at the top level.
 */
function containerFor(
  template: RemoteConfigTemplate,
  name: string,
): Record<string, RemoteConfigParameter> {
  for (const grp of Object.values(template.parameterGroups ?? {})) {
    if (grp.parameters && name in grp.parameters) return grp.parameters;
  }
  template.parameters = template.parameters ?? {};
  return template.parameters;
}

/** Reads the live Remote Config template as a flat, serializable view. */
export const getRemoteConfigTemplate = onCall({ region: REGION }, async (request) => {
  await assertAdmin(request);
  const template = await wrap('getRemoteConfigTemplate', () => remoteConfig.getTemplate());
  return toView(template);
});

/**
 * Applies a batch of create/update/delete changes and publishes the template
 * ONCE (Remote Config publishes the whole template atomically — this is why
 * there is a single batch endpoint rather than per-parameter publishers).
 */
export const publishRemoteConfig = onCall<PublishData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const changes = request.data?.changes;
    if (!Array.isArray(changes) || changes.length === 0) {
      throw new HttpsError('invalid-argument', 'No changes to publish.');
    }

    const template = await wrap('getTemplate', () => remoteConfig.getTemplate());
    template.parameters = template.parameters ?? {};

    for (const change of changes) {
      if (!change.name?.trim()) {
        throw new HttpsError('invalid-argument', 'A parameter name is required.');
      }
      // Update the param wherever it lives (top-level OR inside a group) so
      // Console-grouped params are edited in place, not duplicated.
      const container = containerFor(template, change.name);
      if (change.op === 'delete') {
        delete container[change.name];
      } else {
        container[change.name] = {
          defaultValue: { value: change.value },
          valueType: change.valueType,
          description: change.description ?? '',
        };
      }
    }

    let published: RemoteConfigTemplate;
    try {
      published = await remoteConfig.publishTemplate(template);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Publish failed.';
      throw new HttpsError('internal', `Remote Config publish failed: ${message}`);
    }

    await writeAdminLog({
      actorEmail: admin.email,
      action: 'publishRemoteConfig',
      targetId: published.version?.versionNumber ?? null,
      params: { count: changes.length, ops: changes.map((c) => `${c.op}:${c.name}`) },
      result: `version=${published.version?.versionNumber ?? '?'}`,
    });

    return toView(published);
  },
);

interface UpsertParamData {
  name: string;
  valueType: ParameterValueType;
  value: string;
  description?: string;
}

/** Adds or updates a single parameter and publishes immediately. */
export const upsertRemoteConfigParam = onCall<UpsertParamData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const { name, valueType, value, description } = request.data;
    if (!name?.trim()) throw new HttpsError('invalid-argument', 'A parameter name is required.');

    const template = await wrap('getTemplate', () => remoteConfig.getTemplate());
    containerFor(template, name)[name] = {
      defaultValue: { value },
      valueType,
      description: description ?? '',
    };
    const published = await wrap('publishTemplate', () =>
      remoteConfig.publishTemplate(template),
    );

    await writeAdminLog({
      actorEmail: admin.email,
      action: 'upsertRemoteConfigParam',
      targetId: name,
      params: { valueType },
      result: `version=${published.version?.versionNumber ?? '?'}`,
    });
    return toView(published);
  },
);

/** Deletes a single parameter and publishes immediately. */
export const deleteRemoteConfigParam = onCall<{ name: string }>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const name = request.data?.name;
    if (!name?.trim()) throw new HttpsError('invalid-argument', 'A parameter name is required.');

    const template = await wrap('getTemplate', () => remoteConfig.getTemplate());
    delete containerFor(template, name)[name];
    const published = await wrap('publishTemplate', () =>
      remoteConfig.publishTemplate(template),
    );

    await writeAdminLog({
      actorEmail: admin.email,
      action: 'deleteRemoteConfigParam',
      targetId: name,
      result: `version=${published.version?.versionNumber ?? '?'}`,
    });
    return toView(published);
  },
);

interface RcVersionView {
  versionNumber: string;
  updateTime: string | null;
  updateUserEmail: string | null;
  updateType: string | null;
  description: string | null;
}

/** Lists recent Remote Config template versions (for the History tab). */
export const listRemoteConfigVersions = onCall({ region: REGION }, async (request) => {
  await assertAdmin(request);
  const result = await wrap('listVersions', () => remoteConfig.listVersions({ pageSize: 50 }));
  const versions: RcVersionView[] = (result.versions ?? []).map((v) => ({
    versionNumber: v.versionNumber ?? '',
    updateTime: v.updateTime ?? null,
    updateUserEmail: v.updateUser?.email ?? null,
    updateType: v.updateType ?? null,
    description: v.description ?? null,
  }));
  return { versions };
});

/** Rolls the live template back to a previous version. */
export const rollbackRemoteConfig = onCall<{ versionNumber: number }>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const versionNumber = request.data?.versionNumber;
    if (!versionNumber) {
      throw new HttpsError('invalid-argument', 'A version number is required.');
    }
    const rolled = await wrap('rollback', () => remoteConfig.rollback(versionNumber));

    await writeAdminLog({
      actorEmail: admin.email,
      action: 'rollbackRemoteConfig',
      targetId: String(versionNumber),
      result: `version=${rolled.version?.versionNumber ?? '?'}`,
    });
    return toView(rolled);
  },
);
