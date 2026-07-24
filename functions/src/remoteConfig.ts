import type {
  ParameterValueType,
  RemoteConfigTemplate,
} from 'firebase-admin/remote-config';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { assertAdmin } from './lib/assertAdmin';
import { remoteConfig, REGION } from './lib/firebase';
import { writeAdminLog } from './lib/logs';

/** A flattened, serializable view of one Remote Config parameter. */
interface RcParam {
  name: string;
  valueType: ParameterValueType;
  /** The default value as a string, or null when it uses the in-app default. */
  value: string | null;
  description: string;
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

function toView(template: RemoteConfigTemplate): RcTemplateView {
  const parameters: RcParam[] = Object.entries(template.parameters ?? {}).map(
    ([name, param]) => {
      const def = param.defaultValue;
      const value =
        def && 'value' in def && typeof def.value === 'string' ? def.value : null;
      return {
        name,
        valueType: param.valueType ?? 'STRING',
        value,
        description: param.description ?? '',
      };
    },
  );
  parameters.sort((a, b) => a.name.localeCompare(b.name));

  const version = template.version
    ? {
        updateTime: template.version.updateTime ?? null,
        updateUserEmail: template.version.updateUser?.email ?? null,
      }
    : null;

  return { parameters, version };
}

/** Reads the live Remote Config template as a flat, serializable view. */
export const getRemoteConfigTemplate = onCall({ region: REGION }, async (request) => {
  await assertAdmin(request);
  const template = await remoteConfig.getTemplate();
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

    const template = await remoteConfig.getTemplate();
    template.parameters = template.parameters ?? {};

    for (const change of changes) {
      if (!change.name?.trim()) {
        throw new HttpsError('invalid-argument', 'A parameter name is required.');
      }
      if (change.op === 'delete') {
        delete template.parameters[change.name];
      } else {
        template.parameters[change.name] = {
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
