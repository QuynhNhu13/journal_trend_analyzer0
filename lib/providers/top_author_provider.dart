import 'package:flutter/material.dart';
import '../models/author.dart';
import '../services/openalex_service.dart';

class TopAuthorProvider extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService();

  List<TopAuthor> authors = [];
  int maxCount = 1;
  
  bool isLoading = false;
  String errorMessage = "";
  String currentTopic = "";

  /// Bumped on every search start and on [reset]; a response whose generation
  /// no longer matches is stale (superseded or reset) and must not mutate state.
  int _generation = 0;

  Future<void> search(String keyword) async {
    final cleaned = keyword.trim();
    if (cleaned.isEmpty) return;

    final int gen = ++_generation;
    try {
      isLoading = true;
      errorMessage = "";
      currentTopic = cleaned;
      notifyListeners();

      final result = await _service.fetchTopAuthors(cleaned);
      if (gen != _generation) return; // superseded or reset while loading
      authors = result;

      maxCount = authors.isNotEmpty
        ? authors
            .map((a) => a.worksCount)
            .reduce((a, b) => a > b ? a : b)
        : 1;

    } catch (e) {
      if (gen != _generation) return;
      errorMessage = "Error: $e";
      authors = [];
      maxCount = 1;
    }

    if (gen != _generation) return;
    isLoading = false;
    notifyListeners();
  }

  void reset() {
    _generation++; // invalidate any in-flight search
    isLoading = false;
    errorMessage = "";
    currentTopic = "";
    authors = [];
    maxCount = 1;
    notifyListeners();
  }
}
