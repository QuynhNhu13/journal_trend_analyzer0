import type { SVGProps } from 'react';

/**
 * Small inline icon set (stroke-based, 24x24). Kept local so the project has no
 * heavy icon dependency — matching the "no heavy UI libraries" constraint.
 */
export type IconName =
  | 'dashboard'
  | 'users'
  | 'bell'
  | 'sliders'
  | 'file'
  | 'logout'
  | 'menu'
  | 'close'
  | 'google'
  | 'shield'
  | 'lock'
  | 'spark'
  | 'chevronRight'
  | 'chevronLeft'
  | 'sidebar'
  | 'inbox'
  | 'alert'
  | 'external'
  | 'copy'
  | 'trash'
  | 'list'
  | 'plus'
  | 'folder'
  | 'upload'
  | 'download'
  | 'pencil'
  | 'check'
  | 'send'
  | 'refresh'
  | 'unlock'
  | 'home'
  | 'database'
  | 'harddrive'
  | 'key'
  | 'history'
  | 'more';

type IconProps = SVGProps<SVGSVGElement> & { name: IconName };

// Each entry is the inner markup of a 24x24, 0-24 viewBox icon.
const PATHS: Record<IconName, JSX.Element> = {
  dashboard: (
    <>
      <rect x="3" y="3" width="7" height="9" rx="1.5" />
      <rect x="14" y="3" width="7" height="5" rx="1.5" />
      <rect x="14" y="12" width="7" height="9" rx="1.5" />
      <rect x="3" y="16" width="7" height="5" rx="1.5" />
    </>
  ),
  users: (
    <>
      <circle cx="9" cy="8" r="3.2" />
      <path d="M3.5 20a5.5 5.5 0 0 1 11 0" />
      <path d="M16 5.2a3.2 3.2 0 0 1 0 5.6" />
      <path d="M17.5 14.4A5.5 5.5 0 0 1 20.5 20" />
    </>
  ),
  bell: (
    <>
      <path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6Z" />
      <path d="M10 20a2 2 0 0 0 4 0" />
    </>
  ),
  sliders: (
    <>
      <line x1="4" y1="7" x2="20" y2="7" />
      <line x1="4" y1="17" x2="20" y2="17" />
      <circle cx="9" cy="7" r="2.4" />
      <circle cx="15" cy="17" r="2.4" />
    </>
  ),
  file: (
    <>
      <path d="M6 3h8l4 4v14H6Z" />
      <path d="M14 3v4h4" />
      <line x1="9" y1="13" x2="15" y2="13" />
      <line x1="9" y1="16.5" x2="15" y2="16.5" />
    </>
  ),
  logout: (
    <>
      <path d="M15 4h3a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-3" />
      <path d="M10 12h9" />
      <path d="M13 8l-4 4 4 4" />
    </>
  ),
  menu: (
    <>
      <line x1="4" y1="7" x2="20" y2="7" />
      <line x1="4" y1="12" x2="20" y2="12" />
      <line x1="4" y1="17" x2="20" y2="17" />
    </>
  ),
  close: (
    <>
      <line x1="6" y1="6" x2="18" y2="18" />
      <line x1="18" y1="6" x2="6" y2="18" />
    </>
  ),
  google: (
    <>
      <path
        fill="#4285F4"
        stroke="none"
        d="M21.6 12.23c0-.68-.06-1.36-.18-2.02H12v3.82h5.4a4.62 4.62 0 0 1-2 3.03v2.5h3.24c1.9-1.75 2.96-4.33 2.96-7.33Z"
      />
      <path
        fill="#34A853"
        stroke="none"
        d="M12 22c2.7 0 4.97-.9 6.63-2.44l-3.24-2.5c-.9.6-2.05.96-3.39.96-2.6 0-4.8-1.76-5.59-4.12H3.06v2.58A10 10 0 0 0 12 22Z"
      />
      <path
        fill="#FBBC05"
        stroke="none"
        d="M6.41 13.9a6 6 0 0 1 0-3.8V7.52H3.06a10 10 0 0 0 0 8.96l3.35-2.58Z"
      />
      <path
        fill="#EA4335"
        stroke="none"
        d="M12 5.98c1.47 0 2.79.5 3.83 1.5l2.87-2.87A10 10 0 0 0 3.06 7.52l3.35 2.58C7.2 7.74 9.4 5.98 12 5.98Z"
      />
    </>
  ),
  shield: (
    <>
      <path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6Z" />
      <path d="M9 12l2 2 4-4" />
    </>
  ),
  lock: (
    <>
      <rect x="5" y="11" width="14" height="9" rx="2" />
      <path d="M8 11V8a4 4 0 0 1 8 0v3" />
    </>
  ),
  spark: (
    <>
      <path d="M12 3v4M12 17v4M3 12h4M17 12h4" />
      <path d="M6.5 6.5l2.5 2.5M15 15l2.5 2.5M17.5 6.5L15 9M9 15l-2.5 2.5" />
    </>
  ),
  chevronRight: <path d="M9 6l6 6-6 6" />,
  chevronLeft: <path d="M15 6l-6 6 6 6" />,
  sidebar: (
    <>
      <rect x="3" y="4" width="18" height="16" rx="2" />
      <line x1="9" y1="4" x2="9" y2="20" />
    </>
  ),
  inbox: (
    <>
      <path d="M4 13l2.5-8h11L20 13v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1Z" />
      <path d="M4 13h4l1.5 2.5h5L16 13h4" />
    </>
  ),
  alert: (
    <>
      <path d="M12 4l9 16H3Z" />
      <line x1="12" y1="10" x2="12" y2="14" />
      <line x1="12" y1="17" x2="12" y2="17.5" />
    </>
  ),
  external: (
    <>
      <path d="M14 4h6v6" />
      <path d="M20 4l-9 9" />
      <path d="M18 13v5a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h5" />
    </>
  ),
  copy: (
    <>
      <rect x="9" y="9" width="11" height="11" rx="2" />
      <path d="M6 15H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v1" />
    </>
  ),
  trash: (
    <>
      <path d="M4 7h16" />
      <path d="M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
      <path d="M6 7l1 12a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1l1-12" />
      <line x1="10" y1="11" x2="10" y2="17" />
      <line x1="14" y1="11" x2="14" y2="17" />
    </>
  ),
  list: (
    <>
      <line x1="8" y1="7" x2="20" y2="7" />
      <line x1="8" y1="12" x2="20" y2="12" />
      <line x1="8" y1="17" x2="20" y2="17" />
      <circle cx="4" cy="7" r="1" />
      <circle cx="4" cy="12" r="1" />
      <circle cx="4" cy="17" r="1" />
    </>
  ),
  plus: (
    <>
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </>
  ),
  folder: <path d="M3 7a1 1 0 0 1 1-1h5l2 2h8a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1Z" />,
  upload: (
    <>
      <path d="M4 15v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3" />
      <path d="M12 4v12" />
      <path d="M8 8l4-4 4 4" />
    </>
  ),
  download: (
    <>
      <path d="M4 15v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3" />
      <path d="M12 4v12" />
      <path d="M8 12l4 4 4-4" />
    </>
  ),
  pencil: (
    <>
      <path d="M4 20h4L18.5 9.5a2 2 0 0 0-2.83-2.83L5 17.5V20Z" />
      <path d="M14 7l3 3" />
    </>
  ),
  check: <path d="M5 12l5 5L20 7" />,
  send: (
    <>
      <path d="M4 12l16-7-7 16-2.5-6.5L4 12Z" />
    </>
  ),
  refresh: (
    <>
      <path d="M4 12a8 8 0 0 1 13.7-5.6L20 9" />
      <path d="M20 4v5h-5" />
      <path d="M20 12a8 8 0 0 1-13.7 5.6L4 15" />
      <path d="M4 20v-5h5" />
    </>
  ),
  unlock: (
    <>
      <rect x="5" y="11" width="14" height="9" rx="2" />
      <path d="M8 11V8a4 4 0 0 1 7.5-2" />
    </>
  ),
  home: (
    <>
      <path d="M4 11l8-7 8 7" />
      <path d="M6 10v9a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1v-9" />
    </>
  ),
  database: (
    <>
      <ellipse cx="12" cy="6" rx="7" ry="3" />
      <path d="M5 6v6c0 1.66 3.13 3 7 3s7-1.34 7-3V6" />
      <path d="M5 12v6c0 1.66 3.13 3 7 3s7-1.34 7-3v-6" />
    </>
  ),
  harddrive: (
    <>
      <rect x="3" y="12" width="18" height="7" rx="2" />
      <path d="M5 12l2.5-6h9L19 12" />
      <line x1="7" y1="15.5" x2="7" y2="15.5" />
      <line x1="11" y1="15.5" x2="16" y2="15.5" />
    </>
  ),
  key: (
    <>
      <circle cx="8" cy="8" r="4" />
      <path d="M11 11l7 7" />
      <path d="M16 16l2-2" />
      <path d="M18.5 18.5l1.5-1.5" />
    </>
  ),
  history: (
    <>
      <path d="M4 12a8 8 0 1 1 3 6.2" />
      <path d="M4 20v-5h5" />
      <path d="M12 8v4l3 2" />
    </>
  ),
  more: (
    <>
      <circle cx="12" cy="5" r="1.4" />
      <circle cx="12" cy="12" r="1.4" />
      <circle cx="12" cy="19" r="1.4" />
    </>
  ),
};

export function Icon({ name, ...props }: IconProps) {
  const isColored = name === 'google';
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke={isColored ? 'none' : 'currentColor'}
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...props}
    >
      {PATHS[name]}
    </svg>
  );
}
