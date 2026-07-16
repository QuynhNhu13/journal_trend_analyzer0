import 'package:flutter/material.dart';

import '../services/openalex_service.dart';

class TopJournalProvider extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService();

  List<MapEntry<String, int>> journals = [];
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

      final publications = await _service.searchPublication(cleaned);
      if (gen != _generation) return; // superseded or reset while loading

      final Map<String, int> counts = {};
      for (var p in publications) {
        if (p.journal.isNotEmpty) {
          counts[p.journal] = (counts[p.journal] ?? 0) + 1;
        }
      }

      journals = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      maxCount = journals.isNotEmpty ? journals.first.value : 1;

    } catch (e) {
      if (gen != _generation) return;
      errorMessage = "Error: $e";
      journals = [];
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
    journals = [];
    maxCount = 1;
    notifyListeners();
  }
}
