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

      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => ExportedReport.fromJson(e as Map<String, dynamic>))
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
