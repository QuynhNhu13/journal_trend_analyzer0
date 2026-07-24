import 'package:firebase_core/firebase_core.dart';
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

  /// Bị Firebase giới hạn tần suất (server-side throttle). Client dùng
  /// [Duration.zero] KHÔNG chặn được throttle phía server khi bấm quá nhanh.
  throttled,

  /// Firebase chưa sẵn sàng, hoặc fetch thất bại (mạng / exception khác).
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
  bool _configured = false;

  FirebaseRemoteConfig? get _rc =>
      firebaseReady ? FirebaseRemoteConfig.instance : null;

  /// Khoảng CÁCH tối thiểu giữa 2 lần fetch server.
  ///
  /// TODO(prod): sau khi nộp bài, đổi về `Duration(hours: 1)` cho production để
  /// không gọi fetch quá thường xuyên.
  ///
  /// Dùng [Duration.zero] cho MỌI bản build (kể cả release) trong giai đoạn
  /// demo — KHÔNG gate theo kDebugMode. Nếu chỉ đặt zero cho debug thì bản
  /// release rơi về mặc định 12 giờ của SDK ⇒ bấm Refresh luôn trả cache, giá
  /// trị không đổi. Lưu ý: zero chỉ bỏ throttle phía CLIENT; server vẫn có thể
  /// throttle nếu bấm quá nhanh (xử lý riêng trong [refresh]).
  static const Duration _minimumFetchInterval = Duration.zero;

  /// Áp settings ([Duration.zero]) + defaults MỘT lần, idempotent. Gọi cả trong
  /// [init] lẫn [refresh] để dù [init] có bị bỏ qua thì Refresh vẫn luôn fetch
  /// server thật thay vì đọc cache 12 giờ.
  Future<void> _ensureConfigured(FirebaseRemoteConfig rc) async {
    if (_configured) return;
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: _minimumFetchInterval,
    ));
    // Defaults (best practice): app vẫn có 10/20 khi server trống hoặc offline.
    // fetchAndActivate() sẽ GHI ĐÈ chúng khi server có giá trị.
    await rc.setDefaults(const {
      keyMaxJournals: defaultMaxJournals,
      keyMaxKeywords: defaultMaxKeywords,
    });
    _configured = true;
  }

  Future<void> init() async {
    if (!firebaseReady || _initialized) return;
    try {
      final rc = _rc!;
      await _ensureConfigured(rc);
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
  /// thành công / không đổi / bị throttle / thất bại — không nuốt lỗi im lặng.
  Future<RemoteConfigRefreshResult> refresh() async {
    final rc = _rc;
    if (rc == null) {
      debugPrint('⚠️ Remote Config refresh bỏ qua: Firebase chưa sẵn sàng.');
      return RemoteConfigRefreshResult.failed;
    }
    try {
      // Đảm bảo settings Duration.zero đã áp trước khi fetch (kể cả khi init bị
      // bỏ qua) ⇒ Refresh luôn hỏi server, không trả cache.
      await _ensureConfigured(rc);
      final activated = await rc.fetchAndActivate();
      debugPrint('🔄 Remote Config refresh: activated=$activated, '
          'status=${rc.lastFetchStatus}, time=${rc.lastFetchTime}, '
          'journals=$maxJournals, keywords=$maxKeywords');
      return activated
          ? RemoteConfigRefreshResult.activated
          : RemoteConfigRefreshResult.noChange;
    } on FirebaseException catch (e) {
      // Remote Config báo throttle phía SERVER qua FirebaseException code
      // 'throttled' (hoặc lastFetchStatus == throttle). Client Duration.zero
      // KHÔNG chặn được throttle server khi bấm quá nhanh.
      final throttled = e.code == 'throttled' ||
          rc.lastFetchStatus == RemoteConfigFetchStatus.throttle;
      debugPrint('${throttled ? "⏳ throttled" : "❌ RC error"}: '
          'code=${e.code} msg=${e.message} '
          '(status=${rc.lastFetchStatus}, time=${rc.lastFetchTime})');
      if (throttled) {
        // Vẫn activate giá trị fetch gần nhất để UI phản ánh dữ liệu mới nhất
        // đang có, và báo người dùng thử lại sau thay vì im lặng.
        try {
          await rc.activate();
        } catch (_) {
          // activate có thể ném nếu chưa từng fetch — bỏ qua, giữ giá trị hiện tại.
        }
        return RemoteConfigRefreshResult.throttled;
      }
      return RemoteConfigRefreshResult.failed;
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
