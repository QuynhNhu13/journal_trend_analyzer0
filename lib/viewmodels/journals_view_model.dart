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

  List<JournalStat> journals = [];
  bool isLoading = false;
  String errorMessage = '';
  String currentTopic = '';

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
        return JournalStat(
          name: e.key,
          publicationCount: e.value.length,
          totalCitations: totalCites,
          publications: e.value..sort((a, b) => b.citationCount.compareTo(a.citationCount)),
        );
      }).toList()
        ..sort((a, b) => b.publicationCount.compareTo(a.publicationCount));

      final limit = RemoteConfigService.instance.maxJournals;
      journals = stats.take(limit).toList();
    } catch (e) {
      if (cleaned != currentTopic) return;
      errorMessage = 'Không tải được dữ liệu tạp chí: $e';
      journals = [];
    }

    if (cleaned != currentTopic) return;
    isLoading = false;
    notifyListeners();
  }

  void reset() {
    journals = [];
    errorMessage = '';
    currentTopic = '';
    isLoading = false;
    notifyListeners();
  }
}
