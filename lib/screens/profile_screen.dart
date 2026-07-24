import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase/crashlytics_service.dart';
import '../firebase/messaging_service.dart';
import '../firebase/remote_config_service.dart';
import '../l10n/locale_provider.dart';
import '../models/exported_report.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../utils/widget_keys.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/journals_view_model.dart';
import '../viewmodels/keywords_view_model.dart';
import '../viewmodels/profile_view_model.dart';
import '../widgets/common.dart';

/// Profile screen (lab §4.8): user info, Notification Center, Report Export,
/// Remote Config demo and Crashlytics demo.
class ProfileScreen extends StatefulWidget {
  /// Opens the shared app drawer from the header's hamburger button, matching
  /// the Home/Journals/Keywords tabs.
  final VoidCallback? onMenuTap;
  const ProfileScreen({super.key, this.onMenuTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// How many history entries show before "View all" is tapped.
  static const int _historyPreviewCount = 3;
  static final DateFormat _historyDateFormat = DateFormat('dd/MM/yyyy HH:mm');

  bool _showAllReports = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BrandedHeader(
          title: context.s.profileTitle,
          subtitle: context.s.profileSubtitle,
          onMenuTap: widget.onMenuTap,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _userCard(),
              const SizedBox(height: 20),
              _notificationCenter(),
              const SizedBox(height: 20),
              _reportExport(),
              const SizedBox(height: 20),
              _remoteConfig(),
              const SizedBox(height: 20),
              _crashlytics(),
              const SizedBox(height: 24),
              _signOutButton(),
            ],
          ),
        ),
      ],
    );
  }

  // ── User info ──
  Widget _userCard() {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;
    final name = user?.displayName ??
        (auth.demoMode ? context.s.profileDemoName : context.s.profileGuestName);
    final email = user?.email ?? context.s.profileNotSignedIn;
    final photo = user?.photoURL;

    return SectionCard(
      key: const ValueKey(WidgetKeys.profileUserCard),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primarySoft,
            // Use Image.network with an errorBuilder so a stale/unreachable
            // photo URL falls back to the person icon instead of throwing.
            child: photo == null
                ? const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 32)
                : ClipOval(
                    child: Image.network(
                      photo,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 32),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Notification Center ──
  Widget _notificationCenter() {
    final messaging = context.watch<MessagingService>();
    final items = messaging.notifications;
    return SectionCard(
      key: const ValueKey(WidgetKeys.notificationCenterCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
              title: context.s.notificationCenterTitle,
              icon: Icons.notifications_rounded),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(context.s.noNotifications,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            )
          else
            ...items.map((n) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13.5)),
                            if (n.body.isNotEmpty)
                              Text(n.body,
                                  style: const TextStyle(
                                      fontSize: 12.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ── Report Export ──
  Widget _reportExport() {
    final profile = context.watch<ProfileViewModel>();
    final dashboard = context.watch<DashboardProvider>();
    final summary = dashboard.dashboardSummary;
    final topic = dashboard.currentTopic;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
              title: context.s.exportPdfTitle,
              icon: Icons.picture_as_pdf_rounded),
          const SizedBox(height: 12),
          if (summary == null)
            Text(context.s.exportPdfHint,
                style: const TextStyle(color: AppColors.muted, fontSize: 13))
          else ...[
            Text(context.s.exportTopicLabel(topic),
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const ValueKey(WidgetKeys.exportPdfButton),
                onPressed: profile.exporting
                    ? null
                    : () => context
                        .read<ProfileViewModel>()
                        .exportAndUpload(topic: topic, summary: summary),
                icon: profile.exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(profile.exporting
                    ? context.s.exportInProgress
                    : context.s.exportButton),
              ),
            ),
            if (profile.exportError != null) ...[
              const SizedBox(height: 10),
              Text(profile.exportError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ],
            if (profile.reportUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.emerald, size: 18),
                        const SizedBox(width: 8),
                        Text(context.s.uploadedToStorage,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(profile.reportUrl!,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.body)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _openUrl(profile.reportUrl!),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: Text(context.s.open),
                        ),
                        TextButton.icon(
                          onPressed: () => _copyUrl(profile.reportUrl!),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(context.s.copy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
          // History lives outside the `summary == null` branch: past reports
          // stay reachable even before the user has searched a topic.
          if (profile.history.isNotEmpty) ..._exportHistory(profile),
        ],
      ),
    );
  }

  // ── Exported reports history (local only) ──
  List<Widget> _exportHistory(ProfileViewModel profile) {
    final reports = profile.history;
    final visible =
        _showAllReports ? reports : reports.take(_historyPreviewCount).toList();

    return [
      const SizedBox(height: 20),
      const Divider(height: 1),
      const SizedBox(height: 14),
      SectionTitle(
          title: context.s.exportedReportsTitle, icon: Icons.history_rounded),
      const SizedBox(height: 4),
      for (final report in visible) _historyTile(report),
      if (reports.length > _historyPreviewCount)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _showAllReports = !_showAllReports),
            icon: Icon(
                _showAllReports
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18),
            label: Text(_showAllReports
                ? context.s.exportedReportsShowLess
                : context.s.exportedReportsViewAll),
          ),
        ),
    ];
  }

  Widget _historyTile(ExportedReport report) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.topic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_historyDateFormat.format(report.exportedAt),
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openUrl(report.url),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            tooltip: context.s.open,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => _copyUrl(report.url),
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: context.s.copy,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => _confirmRemoveReport(report),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.danger),
            tooltip: context.s.exportedReportsRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Removes the entry from the local history only — the file in Firebase
  /// Storage is never touched.
  Future<void> _confirmRemoveReport(ExportedReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.s.exportedReportsRemoveTitle),
        content: Text(context.s.exportedReportsRemoveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.s.exportedReportsRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<ProfileViewModel>().removeFromHistory(report);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.exportedReportsRemoved)),
    );
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.urlCopied)),
    );
  }

  /// Handler for the Remote Config "Refresh" button. Wrapped in a try/catch so
  /// ANY failure surfaces as a SnackBar (with the real error text) instead of an
  /// unhandled gesture exception that shows nothing.
  Future<void> _onRefreshRemoteConfig() async {
    // Capture everything that needs `context` BEFORE the await — using context
    // across the async gap is what threw before and swallowed the error.
    // Use `read` (listen: false) for the strings: `context.s` listens to
    // LocaleProvider, and listening inside an event handler is an error
    // ("Provider.of without passing listen: false").
    final messenger = ScaffoldMessenger.of(context);
    final s = context.read<LocaleProvider>().strings;
    final journalsVm = context.read<JournalsViewModel>();
    final keywordsVm = context.read<KeywordsViewModel>();
    try {
      final result = await RemoteConfigService.instance.refresh();
      if (!mounted) return;
      setState(() {}); // các dòng giá trị đọc lại rc.maxJournals/…
      // Re-slice the Journals & Keywords tabs to the new limits so they reflect
      // the change without a re-search or app restart.
      journalsVm.reapplyLimit();
      keywordsVm.reapplyLimit();
      final msg = switch (result) {
        RemoteConfigRefreshResult.activated => s.remoteConfigUpdated,
        RemoteConfigRefreshResult.noChange => s.remoteConfigNoChange,
        RemoteConfigRefreshResult.throttled => s.remoteConfigThrottled,
        RemoteConfigRefreshResult.failed => s.remoteConfigFetchFailed,
      };
      messenger.showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    } catch (e, st) {
      // Never let the tap handler crash — show the real cause so it can be fixed.
      debugPrint('❌ Remote Config refresh handler crashed: $e\n$st');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Refresh error: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ── Remote Config ──
  Widget _remoteConfig() {
    final rc = RemoteConfigService.instance;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionTitle(
                    title: context.s.remoteConfigTitle,
                    icon: Icons.tune_rounded),
              ),
              TextButton.icon(
                key: const ValueKey(WidgetKeys.remoteConfigRefresh),
                onPressed: _onRefreshRemoteConfig,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(context.s.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _configRow(context.s.rcMaxJournalsLabel, '${rc.maxJournals}',
              valueKey: const ValueKey(WidgetKeys.remoteConfigJournalsValue)),
          const Divider(height: 20),
          _configRow(context.s.rcMaxKeywordsLabel, '${rc.maxKeywords}',
              valueKey: const ValueKey(WidgetKeys.remoteConfigKeywordsValue)),
          const SizedBox(height: 12),
          Text(context.s.remoteConfigCaption,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.faint,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _configRow(String label, String value, {Key? valueKey}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.body)),
        // Key phải nằm TRÊN pill giá trị, KHÔNG phải trên Row.
        //
        // Row dùng spaceBetween ⇒ nhãn dạt trái, pill dạt phải, TÂM của Row là
        // khoảng trống. patrol scrollTo/waitUntilVisible/.visible đều kiểm tra
        // hit-testable tại TÂM (Alignment.center) ⇒ với Row rỗng ở giữa, widget
        // "không bao giờ được nhận" nên cuộn mãi không dừng. Pill có Text ở giữa
        // nên hit-testable tại tâm — và cũng chính là "giá trị" test cần verify.
        Container(
          key: valueKey,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.primary)),
        ),
      ],
    );
  }

  // ── Crashlytics ──
  Widget _crashlytics() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
              title: context.s.crashlyticsDemoTitle,
              icon: Icons.bug_report_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await CrashlyticsService.instance.logHandledException();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.s.handledExceptionSent)),
                      );
                    }
                  },
                  child: Text(context.s.handledExceptionButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger),
                  onPressed: () => CrashlyticsService.instance.forceCrash(),
                  child: Text(context.s.testCrashButton),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(context.s.crashlyticsHint,
              style: const TextStyle(fontSize: 11.5, color: AppColors.faint)),
        ],
      ),
    );
  }

  Widget _signOutButton() {
    final auth = context.watch<AuthViewModel>();
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const ValueKey(WidgetKeys.signoutButton),
        onPressed: auth.busy
            ? null
            : () => context.read<AuthViewModel>().signOut(),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(context.s.signOut),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    // Treat launchUrl as the source of truth (avoids a check-then-act race with
    // canLaunchUrl) and surface any failure to the user instead of failing
    // silently. Uri.parse is inside the try so a malformed persisted URL uses
    // the same failure handling.
    try {
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.linkOpenFailed)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.linkOpenFailedDetail('$e'))),
        );
      }
    }
  }
}
