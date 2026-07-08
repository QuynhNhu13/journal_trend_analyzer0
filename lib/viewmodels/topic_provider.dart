import 'package:flutter/foundation.dart';

/// Shared "currently selected research topic" across the Home / Journals /
/// Keywords tabs, so switching tabs keeps context.
class TopicProvider extends ChangeNotifier {
  String _topic = '';
  String get topic => _topic;
  bool get hasTopic => _topic.trim().isNotEmpty;

  void setTopic(String topic) {
    final cleaned = topic.trim();
    if (cleaned.isEmpty || cleaned == _topic) return;
    _topic = cleaned;
    notifyListeners();
  }
}
