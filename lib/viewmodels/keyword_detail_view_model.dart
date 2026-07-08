import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';

/// ViewModel for Keyword Details (lab §4.7): trends, related journals,
/// related publications, and top contributing authors (ranked descending).
class KeywordDetailViewModel extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService();

  bool isLoading = false;
  String errorMessage = '';

  List<PublicationTrendPoint> trend = [];
  List<TopAuthor> authors = [];
  List<Publication> publications = [];
  List<MapEntry<String, int>> journals = [];

  Future<void> load(String keyword) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchPublicationTrend(keyword),
        _service.fetchTopAuthors(keyword),
        _service.searchPublication(keyword),
      ]);

      trend = (results[0] as List<PublicationTrendPoint>)
          .where((t) => t.year >= 1900 && t.year <= DateTime.now().year)
          .toList()
        ..sort((a, b) => a.year.compareTo(b.year));

      // Authors ranked descending by works count (§4.7 requirement).
      authors = (results[1] as List<TopAuthor>).take(10).toList();

      final pubs = results[2] as List<Publication>;
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
      errorMessage = 'Không tải được dữ liệu từ khóa: $e';
    }

    isLoading = false;
    notifyListeners();
  }
}
