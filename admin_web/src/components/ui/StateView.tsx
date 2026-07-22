import { strings } from '../../constants/strings';
import { Icon, type IconName } from './Icon';
import { Spinner } from './Spinner';

/** Centered loading state with an optional message. */
export function LoadingState({ message = strings.states.loading }: { message?: string }) {
  return (
    <div className="grid place-items-center py-16 text-center">
      <Spinner />
      <p className="mt-4 text-sm text-muted">{message}</p>
    </div>
  );
}

/** Centered empty state: soft-pink icon bubble + title + optional message. */
export function EmptyState({
  icon = 'inbox',
  title = strings.states.emptyTitle,
  message,
}: {
  icon?: IconName;
  title?: string;
  message?: string;
}) {
  return (
    <div className="grid place-items-center px-6 py-16 text-center">
      <span className="grid h-20 w-20 place-items-center rounded-full bg-brand-soft text-brand">
        <Icon name={icon} className="h-9 w-9" />
      </span>
      <h3 className="mt-5 text-lg font-bold text-ink">{title}</h3>
      {message ? <p className="mt-2 max-w-sm text-sm text-muted">{message}</p> : null}
    </div>
  );
}

/** Centered error state with an optional retry button. */
export function ErrorState({
  title = strings.states.errorTitle,
  message,
  onRetry,
}: {
  title?: string;
  message?: string;
  onRetry?: () => void;
}) {
  return (
    <div className="grid place-items-center px-6 py-16 text-center">
      <span className="grid h-20 w-20 place-items-center rounded-full bg-danger/10 text-danger">
        <Icon name="alert" className="h-9 w-9" />
      </span>
      <h3 className="mt-5 text-lg font-bold text-ink">{title}</h3>
      {message ? <p className="mt-2 max-w-sm text-sm text-muted">{message}</p> : null}
      {onRetry ? (
        <button
          type="button"
          onClick={onRetry}
          className="mt-6 rounded-sm bg-brand px-5 py-2.5 text-sm font-bold text-white transition hover:bg-brand-bright"
        >
          {strings.states.retry}
        </button>
      ) : null}
    </div>
  );
}
