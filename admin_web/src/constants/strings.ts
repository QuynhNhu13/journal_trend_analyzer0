/**
 * Centralized UI strings for the admin dashboard.
 *
 * All user-facing copy lives here (English for now) so that adding i18n later is
 * a matter of swapping this object for a locale-keyed lookup rather than hunting
 * strings across components.
 */
export const strings = {
  app: {
    name: 'Journal Trend Analyzer',
    adminSuffix: 'Admin',
    tagline: 'Firebase administration console',
  },

  login: {
    title: 'Admin Console',
    subtitle: 'Sign in with your authorized Google account to manage the Journal Trend Analyzer backend.',
    googleButton: 'Sign in with Google',
    signingIn: 'Signing in…',
    poweredBy: 'Secured by Firebase Authentication',
    error: 'Sign-in failed. Please try again.',
  },

  accessDenied: {
    title: 'Access denied',
    message:
      'This Google account is not registered as an administrator. Ask a project owner to add your email to the "admins" collection, then sign in again.',
    signOut: 'Sign out',
  },

  auth: {
    checking: 'Verifying your access…',
    signOut: 'Sign out',
    signingOut: 'Signing out…',
  },

  nav: {
    dashboard: 'Overview',
    users: 'User management',
    notifications: 'Notifications',
    config: 'Remote Config',
    reports: 'PDF reports',
    sectionMain: 'General',
    sectionFirebase: 'Firebase services',
  },

  pages: {
    dashboard: {
      title: 'Overview',
      subtitle: 'System status and quick access to Firebase services',
    },
    users: {
      title: 'User management',
      subtitle: 'View and manage authenticated app users',
    },
    notifications: {
      title: 'Notifications',
      subtitle: 'Send push messages to app users via Cloud Messaging',
    },
    config: {
      title: 'Remote Config',
      subtitle: 'Tune runtime parameters without shipping an app update',
    },
    reports: {
      title: 'PDF reports',
      subtitle: 'Browse exported reports stored in Cloud Storage',
    },
  },

  placeholder: {
    badge: 'Coming soon',
    title: 'Coming in a later phase',
    message:
      'This section is part of the admin console roadmap and will be implemented in a later phase.',
  },

  states: {
    loading: 'Loading…',
    emptyTitle: 'Nothing here yet',
    errorTitle: 'Something went wrong',
    retry: 'Try again',
  },

  topbar: {
    roleLabel: 'Administrator',
  },
} as const;

export type Strings = typeof strings;
