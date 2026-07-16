import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase/crashlytics_service.dart';
import '../firebase/messaging_service.dart';
import '../firebase/remote_config_service.dart';
import '../l10n/locale_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_view_model.dart';
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
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: profile.reportUrl!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.s.urlCopied)),
                            );
                          },
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
        ],
      ),
    );
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
                onPressed: () async {
                  await rc.refresh();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(context.s.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _configRow(context.s.rcMaxJournalsLabel, '${rc.maxJournals}'),
          const Divider(height: 20),
          _configRow(context.s.rcMaxKeywordsLabel, '${rc.maxKeywords}'),
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

  Widget _configRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key,
            style: const TextStyle(fontSize: 13, color: AppColors.body)),
        Container(
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
