import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_provider.dart';
import '../providers/top_author_provider.dart';
import '../providers/top_journal_provider.dart';
import 'journals_view_model.dart';
import 'keywords_view_model.dart';
import 'topic_provider.dart';

/// Clears the shared research topic and returns the Home / Journals / Keywords
/// tabs (and the Dashboard's journal/author previews) to their initial
/// pre-search state.
///
/// This only calls each provider's existing `reset()`/`clear()` API — it does
/// not change any search logic, API calls, or state-management structure.
void clearGlobalTopic(BuildContext context) {
  context.read<TopicProvider>().clear();
  context.read<DashboardProvider>().reset();
  context.read<TopJournalProvider>().reset();
  context.read<TopAuthorProvider>().reset();
  context.read<JournalsViewModel>().reset();
  context.read<KeywordsViewModel>().reset();
}
