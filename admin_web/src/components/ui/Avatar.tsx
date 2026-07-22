/** Round avatar: photo when available, otherwise a brand-tinted initial. */
export function Avatar({
  name,
  photoUrl,
  size = 40,
}: {
  name: string | null;
  photoUrl?: string | null;
  size?: number;
}) {
  const label = (name?.trim() || 'A') as string;
  const initial = label.charAt(0).toUpperCase();

  if (photoUrl) {
    return (
      <img
        src={photoUrl}
        alt={label}
        referrerPolicy="no-referrer"
        width={size}
        height={size}
        className="shrink-0 rounded-full border border-hairline object-cover"
        style={{ width: size, height: size }}
      />
    );
  }

  return (
    <span
      aria-hidden="true"
      className="grid shrink-0 place-items-center rounded-full bg-brand-soft font-extrabold text-brand"
      style={{ width: size, height: size, fontSize: size * 0.4 }}
    >
      {initial}
    </span>
  );
}
