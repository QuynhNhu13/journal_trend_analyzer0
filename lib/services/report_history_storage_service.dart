import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exported_report.dart';

/// Persists the local history of exported PDF reports, mirroring
/// [RecentStorageService]'s fail-safe style: any storage error returns an empty
/// result / no-op so the UI never crashes if persistence is unavailable.
class ReportHistoryStorageService {
  static const _kReports = 'exported_reports';

  Future<List<ExportedReport>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kReports);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      // Handle each persisted record independently: skip non-map or malformed
      // entries (fromJson returns null for those) so one bad record can't throw
      // and wipe the whole history — valid entries are always retained.
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ExportedReport.fromJson)
          .whereType<ExportedReport>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<ExportedReport> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kReports,
        jsonEncode(reports.map((r) => r.toJson()).toList()),
      );
    } catch (_) {
      // ignore persistence errors
    }
  }
}
