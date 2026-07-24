import 'package:flutter/foundation.dart';

import '../firebase/remote_config_service.dart';
import '../models/journal_stat.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';

/// ViewModel for the Journals tab (lab §4.4). Groups a topic's publications
/// by journal and produces per-journal statistics. Honors the
/// `max_journals_displayed` Remote Config value.
class JournalsViewModel extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService.instance;

  /// Full, unsliced result from the last search. [journals] is DERIVED from
  /// this, so the Remote Config limit is applied live on every read — a Profile
  /// Refresh re-slices the list without needing a new search or an app restart.
  List<JournalStat> _all = [];

  bool isLoading = false;
  String errorMessage = '';
  String currentTopic = '';

  /// Journals to display, limited by the current `max_journals_displayed`.
  List<JournalStat> get journals =>
      _all.take(RemoteConfigService.instance.maxJournals).toList();

  /// All journals without limit
  List<JournalStat> get allJournals => _all;

  int get maxCount => journals.isEmpty ? 1 : journals.first.publicationCount;

  Future<void> search(String keyword) async {
    final cleaned = keyword.trim();
    if (cleaned.isEmpty) return;

    isLoading = true;
    errorMessage = '';
    currentTopic = cleaned;
    notifyListeners();

    try {
      final pubs = await _service.searchPublication(cleaned);
      // A newer search superseded this one — drop the stale response.
      if (cleaned != currentTopic) return;

      final Map<String, List<Publication>> grouped = {};
      for (final p in pubs) {
        if (p.journal.trim().isEmpty) continue;
        grouped.putIfAbsent(p.journal, () => []).add(p);
      }

      final stats = grouped.entries.map((e) {
        final totalCites =
            e.value.fold<int>(0, (sum, p) => sum + p.citationCount);
        final issn = e.value.firstWhere((p) => p.issn.isNotEmpty, orElse: () => e.value.first).issn;
        return JournalStat(
          name: e.key,
          issn: issn,
          publicationCount: e.value.length,
          totalCitations: totalCites,
          publications: e.value..sort((a, b) => b.citationCount.compareTo(a.citationCount)),
        );
      }).toList()
        ..sort((a, b) => b.publicationCount.compareTo(a.publicationCount));

      // Keep the FULL list; the `journals` getter applies the live RC limit.
      _all = stats;
    } catch (e) {
      if (cleaned != currentTopic) return;
      errorMessage = 'Không tải được dữ liệu tạp chí: $e';
      _all = [];
    }

    if (cleaned != currentTopic) return;
    isLoading = false;
    notifyListeners();
  }

  void reset() {
    _all = [];
    errorMessage = '';
    currentTopic = '';
    isLoading = false;
    notifyListeners();
  }

  /// Re-emits the (re-sliced) list after `max_journals_displayed` changed, so
  /// the Journals tab reflects a new limit without a re-search or app restart.
  void reapplyLimit() => notifyListeners();
}
