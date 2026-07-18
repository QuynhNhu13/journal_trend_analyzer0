import 'package:flutter/material.dart';
import '../models/dashboard_summary.dart';
import '../services/openalex_service.dart';

class DashboardProvider extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService();

  ResearchDashboardSummary? dashboardSummary;
  bool isLoading = false;
  String errorMessage = "";
  String currentTopic = "";
  int selectedLimit = 50;

  /// True once the user has triggered at least one search. Used to decide
  /// whether the "Papers Retrieved" count should be shown at all.
  bool hasSearched = false;

  /// Real number of papers retrieved from the last successful search.
  /// Stays 0 until a search completes.
  int papersRetrieved = 0;

  /// Incremented on every search start and on [reset]. A response whose
  /// generation no longer matches [_generation] is stale (superseded by a newer
  /// search or invalidated by a reset) and must not mutate state.
  int _generation = 0;

  Future<void> search(String keyword, {int? limit}) async {
    final cleaned = keyword.trim();
    if (cleaned.isEmpty) return;

    if (limit != null) {
      selectedLimit = limit;
    }

    final int gen = ++_generation;
    try {
      isLoading = true;
      errorMessage = "";
      currentTopic = cleaned;
      hasSearched = true;
      notifyListeners();

      final summary =
          await _service.fetchResearchDashboardSummary(cleaned, selectedLimit);
      if (gen != _generation) return; // superseded or reset while loading
      dashboardSummary = summary;
      papersRetrieved = summary.papersRetrieved;
    } catch (e) {
      if (gen != _generation) return;
      errorMessage = "Error: $e";
      dashboardSummary = null;
      papersRetrieved = 0;
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
    dashboardSummary = null;
    hasSearched = false;
    papersRetrieved = 0;
    notifyListeners();
  }
}
