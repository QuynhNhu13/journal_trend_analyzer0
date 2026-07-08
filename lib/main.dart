import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase/analytics_service.dart';
import 'firebase/firebase_bootstrap.dart';
import 'firebase/messaging_service.dart';
import 'l10n/locale_provider.dart';
import 'providers/compare_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/trend_provider.dart';
import 'providers/top_journal_provider.dart';
import 'providers/top_author_provider.dart';
import 'providers/author_detail_provider.dart';
import 'providers/publication_provider.dart';
import 'providers/recent_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/journals_view_model.dart';
import 'viewmodels/keywords_view_model.dart';
import 'viewmodels/profile_view_model.dart';
import 'viewmodels/topic_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  runApp(const JournalTrendApp());
}

/// Root widget wiring every provider. Extracted so Patrol E2E tests can pump
/// the exact same app tree as production.
class JournalTrendApp extends StatelessWidget {
  const JournalTrendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => PublicationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TrendProvider()),
        ChangeNotifierProvider(create: (_) => TopJournalProvider()),
        ChangeNotifierProvider(create: (_) => TopAuthorProvider()),
        ChangeNotifierProvider(create: (_) => AuthorDetailProvider()),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
        ChangeNotifierProvider(create: (_) => RecentProvider()..load()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        // Lab 03 additions
        ChangeNotifierProvider(create: (_) => TopicProvider()),
        ChangeNotifierProvider(create: (_) => JournalsViewModel()),
        ChangeNotifierProvider(create: (_) => KeywordsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider.value(value: MessagingService.instance),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final observer = AnalyticsService.instance.observer;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: context.s.appTitle,
      theme: AppTheme.light(),
      navigatorObservers: [?observer],
      home: const SplashScreen(),
    );
  }
}
