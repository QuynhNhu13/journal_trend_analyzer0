import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';
import '../utils/async_utils.dart';

/// ViewModel for Keyword Details (lab §4.7): trends, related journals,
/// related publications, and top contributing authors (ranked descending).
class KeywordDetailViewModel extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService.instance;

  bool isLoading = false;
  String errorMessage = '';

  /// The keyword of the most recent [load] call, used to discard stale
  /// in-flight responses that would otherwise overwrite newer results.
  String _currentKeyword = '';

  List<PublicationTrendPoint> trend = [];
  List<TopAuthor> authors = [];
  List<Publication> publications = [];
  List<MapEntry<String, int>> journals = [];

  Future<void> load(String keyword) async {
    _currentKeyword = keyword;
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    // Fire all requests concurrently. Trend + authors are ENRICHMENT: degrade to
    // empty on failure so a flaky secondary call can't error the whole page
    // (endless error → retry loop). Publications are the PRIMARY substance — if
    // that fails the page genuinely couldn't load ⇒ error state (+ retry).
    final pubsFuture = _service.searchPublication(keyword);
    final trendFuture = orFallback(
        _service.fetchPublicationTrend(keyword),
        const <PublicationTrendPoint>[]);
    final authorsFuture =
        orFallback(_service.fetchTopAuthors(keyword), const <TopAuthor>[]);

    try {
      final pubs = await pubsFuture;
      final trendData = await trendFuture;
      final authorsData = await authorsFuture;
      // A newer load superseded this one — drop the stale response.
      if (keyword != _currentKeyword) return;

      trend = trendData
          .where((t) => t.year >= 1900 && t.year <= DateTime.now().year)
          .toList()
        ..sort((a, b) => a.year.compareTo(b.year));

      // Authors ranked descending by works count (§4.7 requirement).
      authors = authorsData.take(10).toList();

      publications = (pubs
            ..sort((a, b) => b.citationCount.compareTo(a.citationCount)))
          .take(15)
          .toList();

      final Map<String, int> jc = {};
      for (final p in pubs) {
        if (p.journal.trim().isEmpty) continue;
        jc[p.journal] = (jc[p.journal] ?? 0) + 1;
      }
      journals = jc.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      journals = journals.take(5).toList();
    } catch (e) {
      if (keyword != _currentKeyword) return;
      errorMessage = 'Không tải được dữ liệu từ khóa: $e';
    }

    if (keyword != _currentKeyword) return;
    isLoading = false;
    notifyListeners();
  }
}
