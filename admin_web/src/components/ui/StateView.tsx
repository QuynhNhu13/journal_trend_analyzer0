import type { ReactNode } from 'react';

import { strings } from '../../constants/strings';
import { Icon, type IconName } from './Icon';
import { Spinner } from './Spinner';

/** Centered loading state (prefer skeletons for content; use this sparingly). */
export function LoadingState({ message = strings.states.loading }: { message?: string }) {
  return (
    <div className="grid place-items-center py-16 text-center">
      <Spinner />
      <p className="mt-3 text-sm text-muted">{message}</p>
    </div>
  );
}

/** Empty state: thin outline icon, title, one-line hint, optional action. */
export function EmptyState({
  icon = 'inbox',
  title = strings.states.emptyTitle,
  message,
  action,
}: {
  icon?: IconName;
  title?: string;
  message?: string | null;
  action?: ReactNode;
}) {
  return (
    <div className="grid place-items-center px-6 py-14 text-center">
      <Icon name={icon} className="h-8 w-8 text-faint" />
      <h3 className="mt-3 text-sm font-semibold text-ink">{title}</h3>
      {message ? <p className="mt-1 max-w-sm text-sm text-muted">{message}</p> : null}
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  );
}

/** Error state: red-tinted panel, clear message, retry. */
export function ErrorState({
  title = strings.states.errorTitle,
  message,
  onRetry,
}: {
  title?: string;
  message?: string | null;
  onRetry?: () => void;
}) {
  return (
    <div className="m-4 rounded-lg border border-danger/30 bg-danger/5 px-6 py-10 text-center">
      <Icon name="alert" className="mx-auto h-7 w-7 text-danger" />
      <h3 className="mt-3 text-sm font-semibold text-ink">{title}</h3>
      {message ? <p className="mt-1 text-sm text-muted">{message}</p> : null}
      {onRetry ? (
        <button
          type="button"
          onClick={onRetry}
          className="mt-4 rounded-md border border-hairline bg-card px-3.5 py-2 text-sm font-semibold text-body transition hover:border-brand hover:text-brand"
        >
          {strings.states.retry}
        </button>
      ) : null}
    </div>
  );
}
