/** Brand-colored circular spinner. Size in px via `size` (default 38). */
export function Spinner({
  size = 38,
  className = '',
}: {
  size?: number;
  className?: string;
}) {
  return (
    <span
      role="status"
      aria-label="Loading"
      className={`inline-block animate-spin rounded-full border-brand border-t-transparent ${className}`}
      style={{
        width: size,
        height: size,
        borderWidth: Math.max(2, Math.round(size / 12)),
      }}
    />
  );
}
