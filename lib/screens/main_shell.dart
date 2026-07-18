import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/messaging_service.dart';
import '../l10n/locale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/widget_keys.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/language_toggle.dart';
import 'compare_topics_screen.dart';
import 'dashboard_screen.dart';
import 'journals_screen.dart';
import 'keywords_screen.dart';
import 'profile_screen.dart';
import 'top_author_screen.dart';
import 'top_journal_screen.dart';
import 'trend_screen.dart';

/// Main app scaffold with the required Bottom Navigation Bar (lab §7):
/// Home · Journals · Keywords · Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Notification Center lives on the Profile tab.
  static const int _profileTabIndex = 3;

  @override
  void initState() {
    super.initState();
    // A tapped FCM notification asks us to open the Notification Center.
    MessagingService.instance.addListener(_handleMessagingSignal);
    // Also handle a request that arrived before this widget mounted (e.g. the
    // app was launched from a killed state by tapping a notification).
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _handleMessagingSignal());
  }

  @override
  void dispose() {
    MessagingService.instance.removeListener(_handleMessagingSignal);
    super.dispose();
  }

  void _handleMessagingSignal() {
    if (MessagingService.instance.takeOpenNotificationCenterRequest() &&
        mounted) {
      setState(() => _index = _profileTabIndex);
    }
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardScreen(scaffoldKey: _scaffoldKey),
      JournalsScreen(onMenuTap: _openDrawer),
      KeywordsScreen(onMenuTap: _openDrawer),
      ProfileScreen(onMenuTap: _openDrawer),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Bottom navigation ───────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded,
                  key: ValueKey(WidgetKeys.tabHome)),
              label: context.s.tabHome),
          BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book_rounded,
                  key: ValueKey(WidgetKeys.tabJournals)),
              label: context.s.tabJournals),
          BottomNavigationBarItem(
              icon: const Icon(Icons.tag_rounded,
                  key: ValueKey(WidgetKeys.tabKeywords)),
              label: context.s.tabKeywords),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded,
                  key: ValueKey(WidgetKeys.tabProfile)),
              label: context.s.tabProfile),
        ],
      ),
    );
  }

  // ─── Drawer (extra features) ─────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.card,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            constraints: const BoxConstraints(minHeight: 170),
            decoration: const BoxDecoration(gradient: AppGradients.brand),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.insights_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.s.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _tile(Icons.trending_up_rounded, context.s.menuTrendAnalysis, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TrendScreen()));
          }),
          _tile(Icons.compare_arrows_rounded, context.s.menuCompare, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CompareTopicsScreen()));
          }),
          const Divider(indent: 16, endIndent: 16),
          _tile(Icons.menu_book_rounded, context.s.menuTopJournals, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TopJournalScreen()));
          }),
          _tile(Icons.people_alt_rounded, context.s.menuTopAuthors, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TopAuthorScreen()));
          }),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.language_rounded, color: AppColors.primary),
            title: Text(
              context.s.languageMenu,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.body),
            ),
            trailing: const LanguageToggle(onDark: false),
          ),
          _tile(Icons.logout_rounded, context.s.signOut, () {
            Navigator.pop(context);
            context.read<AuthViewModel>().signOut();
          }),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style:
            const TextStyle(fontWeight: FontWeight.w600, color: AppColors.body),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
