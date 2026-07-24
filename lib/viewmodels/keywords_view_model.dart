import 'package:flutter/foundation.dart';

import '../firebase/remote_config_service.dart';
import '../services/openalex_service.dart';

/// ViewModel for the Keywords tab (lab §4.6). Aggregates the most frequent
/// keywords for a topic. Honors the `max_keywords_displayed` Remote Config value.
class KeywordsViewModel extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService.instance;

  /// Full, unsliced result from the last search. [keywords] is DERIVED from
  /// this, so the Remote Config limit is applied live on every read — a Profile
  /// Refresh re-slices the list without needing a new search or an app restart.
  List<MapEntry<String, int>> _all = [];

  bool isLoading = false;
  String errorMessage = '';
  String currentTopic = '';

  /// Keywords to display, limited by the current `max_keywords_displayed`.
  List<MapEntry<String, int>> get keywords =>
      _all.take(RemoteConfigService.instance.maxKeywords).toList();

  int get maxCount => keywords.isEmpty ? 1 : keywords.first.value;

  Future<void> search(String keyword) async {
    final cleaned = keyword.trim();
    if (cleaned.isEmpty) return;

    isLoading = true;
    errorMessage = '';
    currentTopic = cleaned;
    notifyListeners();

    try {
      final all = await _service.fetchTopKeywords(cleaned);
      // A newer search superseded this one — drop the stale response.
      if (cleaned != currentTopic) return;
      // Keep the FULL list; the `keywords` getter applies the live RC limit.
      _all = all;
    } catch (e) {
      if (cleaned != currentTopic) return;
      errorMessage = 'Không tải được dữ liệu từ khóa: $e';
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

  /// Re-emits the (re-sliced) list after `max_keywords_displayed` changed, so
  /// the Keywords tab reflects a new limit without a re-search or app restart.
  void reapplyLimit() => notifyListeners();
}
