import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';
import '../utils/async_utils.dart';

class TrendProvider extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService();

  List<PublicationTrendPoint> trendData = [];
  List<Publication> topPapers = [];
  
  bool isLoading = false;
  String errorMessage = "";
  String currentTopic = "";

  Future<void> search(String keyword) async {
    final cleaned = keyword.trim();
    if (cleaned.isEmpty) return;

    try {
      isLoading = true;
      errorMessage = "";
      currentTopic = cleaned;
      notifyListeners();

      // PRIMARY: the trend IS the screen — failure ⇒ error state (+ retry). The
      // top-papers list is enrichment: degrade to empty so a hiccup there can't
      // error the whole screen (endless error → retry loop).
      final trendFuture = _service.fetchPublicationTrend(cleaned);
      final topFuture = orFallback(
          _service.fetchTopInfluentialPapers(cleaned), const <Publication>[]);

      trendData = await trendFuture;
      topPapers = await topFuture;
    } catch (e) {
      errorMessage = "Error: $e";
      trendData = [];
      topPapers = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void reset() {
    isLoading = false;
    errorMessage = "";
    currentTopic = "";
    trendData = [];
    topPapers = [];
    notifyListeners();
  }
}
