/// Centralized widget-key identifiers used by the Patrol E2E suite.
///
/// Keeping them in one place keeps the UI and the tests in sync.
///   • UI:   `key: const ValueKey(WidgetKeys.searchFieldHome)`
///   • Test: `$(const Key(WidgetKeys.searchFieldHome))`
class WidgetKeys {
  WidgetKeys._();

  // ── Search bars (Home / Journals / Keywords) + submit buttons ──
  // Distinct submit keys per screen: all three search bars are mounted at once
  // inside the IndexedStack, so a shared key would be ambiguous for finders.
  static const String searchFieldHome = 'search_field_home';
  static const String searchFieldJournals = 'search_field_journals';
  static const String searchFieldKeywords = 'search_field_keywords';
  static const String searchSubmitHome = 'search_submit_home';
  static const String searchSubmitJournals = 'search_submit_journals';
  static const String searchSubmitKeywords = 'search_submit_keywords';

  // ── Bottom navigation tabs ──
  static const String tabHome = 'tab_home';
  static const String tabJournals = 'tab_journals';
  static const String tabKeywords = 'tab_keywords';
  static const String tabProfile = 'tab_profile';

  // ── Auth ──
  static const String googleSigninButton = 'google_signin_button';
  static const String signoutButton = 'signout_button';

  // ── Profile · Remote Config ──
  static const String remoteConfigRefresh = 'remote_config_refresh';
  static const String remoteConfigJournalsValue = 'remote_config_journals_value';
  static const String remoteConfigKeywordsValue = 'remote_config_keywords_value';

  // ── Profile · Report export + Notification Center ──
  static const String exportPdfButton = 'export_pdf_button';
  static const String notificationCenterCard = 'notification_center_card';

  // ── First items of the publication / journal / keyword lists ──
  static const String publicationListFirst = 'publication_list_first';
  static const String journalListFirst = 'journal_list_first';
  static const String keywordListFirst = 'keyword_list_first';

  // ── Per-screen verification anchors ──
  static const String dashboardTotalPapers = 'dashboard_total_papers';
  static const String publicationDetailTitle = 'publication_detail_title';
  static const String journalDetailTitle = 'journal_detail_title';
  static const String keywordDetailTitle = 'keyword_detail_title';
}
