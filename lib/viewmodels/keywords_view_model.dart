import 'package:flutter/foundation.dart';

import '../firebase/remote_config_service.dart';
import '../services/openalex_service.dart';

/// ViewModel for the Keywords tab (lab §4.6). Aggregates the most frequent
/// keywords for a topic. Honors the `max_keywords_displayed` Remote Config value.
class KeywordsViewModel extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService.instance;

  List<MapEntry<String, int>> keywords = [];
  bool isLoading = false;
  String errorMessage = '';
  String currentTopic = '';

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
      final limit = RemoteConfigService.instance.maxKeywords;
      keywords = all.take(limit).toList();
    } catch (e) {
      if (cleaned != currentTopic) return;
      errorMessage = 'Không tải được dữ liệu từ khóa: $e';
      keywords = [];
    }

    if (cleaned != currentTopic) return;
    isLoading = false;
    notifyListeners();
  }

  void reset() {
    keywords = [];
    errorMessage = '';
    currentTopic = '';
    isLoading = false;
    notifyListeners();
  }
}
