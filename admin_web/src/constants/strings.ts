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
    signOutError: 'Sign-out failed. Please try again.',
  },

  nav: {
    dashboard: 'Overview',
    users: 'User management',
    notifications: 'Notifications',
    config: 'Remote Config',
    reports: 'PDF reports',
    sectionMain: 'General',
    sectionFirebase: 'Firebase services',
    drawerLabel: 'Navigation menu',
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

  common: {
    open: 'Open',
    copy: 'Copy',
    copied: 'Link copied',
    delete: 'Delete',
    cancel: 'Cancel',
    close: 'Close',
    retry: 'Try again',
    loadMore: 'Load more',
    search: 'Search',
    all: 'All',
    viewAll: 'View all',
    none: '—',
  },

  users: {
    searchPlaceholder: 'Search by name or email…',
    sortLabel: 'Sort by',
    sortLastLogin: 'Last login',
    sortCreated: 'Created date',
    countLabel: (n: number) => `${n} user${n === 1 ? '' : 's'} loaded`,
    emptyTitle: 'No users yet',
    emptyMessage: 'Once someone signs in to the mobile app, they will appear here.',
    noMatch: 'No users match your search.',
    errorMessage: 'Could not load users from Firestore.',
    col: {
      user: 'User',
      email: 'Email',
      created: 'Created',
      lastLogin: 'Last login',
      searches: 'Searches',
      exports: 'Exports',
    },
    detail: {
      title: 'User details',
      profile: 'Profile',
      activity: 'Activity',
      uid: 'UID',
      platform: 'Platform',
      lastActive: 'Last active',
      reportsTitle: 'Exported reports',
      noReports: 'This user has not exported any reports yet.',
      reportsError: 'Could not load this user’s reports.',
    },
  },

  reports: {
    totalSize: 'Total storage used',
    reportCount: (n: number) => `${n} report${n === 1 ? '' : 's'}`,
    filterTopic: 'Topic',
    filterRange: 'Time range',
    range7: 'Last 7 days',
    range30: 'Last 30 days',
    rangeAll: 'All time',
    allTopics: 'All topics',
    storageWarning:
      'Storage folder could not be read — file sizes and total usage are unavailable.',
    emptyTitle: 'No reports yet',
    emptyMessage: 'Exported PDF reports from the app will show up here.',
    noMatch: 'No reports match the selected filters.',
    errorMessage: 'Could not load reports from Firestore.',
    col: {
      fileName: 'File name',
      topic: 'Topic',
      exportedBy: 'Exported by',
      date: 'Date',
      size: 'Size',
      actions: 'Actions',
    },
    deleteTitle: 'Delete report?',
    deleteMessage: (fileName: string) =>
      `This permanently removes “${fileName}” from Cloud Storage and its Firestore record. This cannot be undone.`,
    deleting: 'Deleting…',
    deleteSuccess: 'Report deleted.',
    deleteError: 'Could not delete the report. Please try again.',
  },

  overview: {
    kpiUsers: 'Total users',
    kpiActive: 'Active (7 days)',
    kpiSearches: 'Total searches',
    kpiReports: 'Reports exported',
    chartTitle: 'Exports per day',
    chartSubtitle: 'Last 14 days',
    chartEmpty: 'No exports in the last 14 days.',
    recentUsers: 'Recent logins',
    recentReports: 'Recent reports',
    recentUsersEmpty: 'No users yet.',
    recentReportsEmpty: 'No reports yet.',
    errorMessage: 'Could not load dashboard metrics from Firestore.',
  },
} as const;

export type Strings = typeof strings;
