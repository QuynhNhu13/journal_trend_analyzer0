import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// Kết quả của một lần [RemoteConfigService.refresh], để UI phản hồi rõ ràng
/// cho người dùng / người demo thay vì im lặng.
enum RemoteConfigRefreshResult {
  /// Fetch thành công VÀ có giá trị mới từ server được kích hoạt.
  activated,

  /// Fetch thành công nhưng không có gì mới (giá trị hiện tại đã là mới nhất).
  noChange,

  /// Firebase chưa sẵn sàng, hoặc fetch thất bại (mạng / throttle / exception).
  failed,
}

/// Wraps Firebase Remote Config (lab §4.8 "Remote Config Demo").
///
/// Exposes two config values required by the lab:
/// - `max_journals_displayed`
/// - `max_keywords_displayed`
///
/// Falls back to sensible defaults when Firebase is not configured yet.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  static const String keyMaxJournals = 'max_journals_displayed';
  static const String keyMaxKeywords = 'max_keywords_displayed';

  static const int defaultMaxJournals = 10;
  static const int defaultMaxKeywords = 20;

  bool _initialized = false;

  FirebaseRemoteConfig? get _rc =>
      firebaseReady ? FirebaseRemoteConfig.instance : null;

  /// Khoảng CÁCH tối thiểu giữa 2 lần fetch server.
  ///
  /// TODO(prod): sau khi nộp bài, đổi về `Duration(hours: 1)` cho production để
  /// không gọi fetch quá thường xuyên.
  ///
  /// Trong giai đoạn phát triển/demo dùng [Duration.zero]: mỗi lần Refresh đều
  /// gọi server thật, KHÔNG bị trả về cache. Mặc định của SDK là 12 giờ (và bản
  /// cũ hard-code 1 giờ) — đó chính là lý do bấm Refresh mà giá trị không đổi:
  /// fetch bị throttle nên chỉ đọc lại cache.
  static const Duration _minimumFetchInterval = Duration.zero;

  Future<void> init() async {
    if (!firebaseReady || _initialized) return;
    try {
      final rc = _rc!;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: _minimumFetchInterval,
      ));
      // Defaults (best practice): app vẫn có 10/20 khi server trống hoặc offline.
      // Đây là lý do app "trông có vẻ chạy" dù Console từng rỗng — nó chạy bằng
      // các default này. fetchAndActivate() sẽ GHI ĐÈ chúng khi server có giá trị.
      await rc.setDefaults(const {
        keyMaxJournals: defaultMaxJournals,
        keyMaxKeywords: defaultMaxKeywords,
      });
      final activated = await rc.fetchAndActivate();
      _initialized = true;
      debugPrint('✅ Remote Config init: activated=$activated, '
          'status=${rc.lastFetchStatus}, time=${rc.lastFetchTime}, '
          'journals=$maxJournals, keywords=$maxKeywords');
    } catch (e) {
      debugPrint('Remote Config init error: $e');
    }
  }

  /// Force a refresh (used by the Profile "Refresh" button).
  ///
  /// Trả về [RemoteConfigRefreshResult] để UI báo cho người dùng biết fetch
  /// thành công / không đổi / thất bại — không nuốt lỗi im lặng nữa.
  Future<RemoteConfigRefreshResult> refresh() async {
    final rc = _rc;
    if (rc == null) {
      debugPrint('⚠️ Remote Config refresh bỏ qua: Firebase chưa sẵn sàng.');
      return RemoteConfigRefreshResult.failed;
    }
    try {
      final activated = await rc.fetchAndActivate();
      debugPrint('🔄 Remote Config refresh: activated=$activated, '
          'status=${rc.lastFetchStatus}, time=${rc.lastFetchTime}, '
          'journals=$maxJournals, keywords=$maxKeywords');
      return activated
          ? RemoteConfigRefreshResult.activated
          : RemoteConfigRefreshResult.noChange;
    } catch (e) {
      debugPrint('❌ Remote Config refresh error: $e '
          '(status=${rc.lastFetchStatus}, time=${rc.lastFetchTime})');
      return RemoteConfigRefreshResult.failed;
    }
  }

  int get maxJournals {
    final v = _rc?.getInt(keyMaxJournals) ?? 0;
    return v > 0 ? v : defaultMaxJournals;
  }

  int get maxKeywords {
    final v = _rc?.getInt(keyMaxKeywords) ?? 0;
    return v > 0 ? v : defaultMaxKeywords;
  }
}
