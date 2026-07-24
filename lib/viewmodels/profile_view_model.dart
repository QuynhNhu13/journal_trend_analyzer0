import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../firebase/analytics_service.dart';
import '../firebase/storage_service.dart';
import '../firebase/user_data_service.dart';
import '../models/dashboard_summary.dart';
import '../models/exported_report.dart';
import '../services/report_history_storage_service.dart';
import '../utils/pdf_report_service.dart';

/// ViewModel for the Profile screen's Report Export flow (lab §4.8):
/// build a PDF → upload to Firebase Storage → expose the download URL, and
/// keep a local history of the reports exported so far.
class ProfileViewModel extends ChangeNotifier {
  final ReportHistoryStorageService _historyStorage;

  ProfileViewModel({ReportHistoryStorageService? historyStorage})
      : _historyStorage = historyStorage ?? ReportHistoryStorageService();

  /// Newest-first cap for the local history.
  static const int maxHistory = 20;

  bool exporting = false;
  String? reportUrl;
  String? exportError;

  List<ExportedReport> _history = [];
  List<ExportedReport> get history => List.unmodifiable(_history);

  /// Serializes every history operation (load + mutations) so their async
  /// storage access and in-memory `_history` updates can't interleave — e.g. a
  /// concurrent [_addToHistory] must not be clobbered by [loadHistory] resolving
  /// its `await` afterwards. Each op holds the chain from storage access through
  /// the in-memory update and [notifyListeners].
  Future<void> _historyOps = Future<void>.value();

  Future<void> _serializeHistory(Future<void> Function() action) {
    final run = _historyOps.then((_) => action());
    // Keep the chain alive even if one op fails, so later ops still run.
    _historyOps = run.catchError((_) {});
    return run;
  }

  /// Loads persisted history into memory. Call once at startup.
  Future<void> loadHistory() => _serializeHistory(() async {
        _history = await _historyStorage.load();
        notifyListeners();
      });

  Future<void> exportAndUpload({
    required String topic,
    required ResearchDashboardSummary summary,
  }) async {
    // Re-entrancy guard: one upload at a time, mirroring AuthViewModel's
    // `_busy` guard. The Export button is already disabled while [exporting],
    // but that only takes effect on the next rebuild — this keeps the "never
    // two uploads in flight" invariant in the ViewModel, where it belongs,
    // instead of relying on the UI to enforce it.
    if (exporting) return;

    exporting = true;
    reportUrl = null;
    exportError = null;
    notifyListeners();

    File? file;
    try {
      file = await PdfReportService.instance
          .buildDashboardReport(topic: topic, summary: summary);
      final fileName = file.uri.pathSegments.last;
      final url = await StorageService.instance.uploadReport(file, fileName);
      reportUrl = url;
      await _addToHistory(
        ExportedReport(
          topic: topic,
          fileName: fileName,
          url: url,
          exportedAt: DateTime.now(),
        ),
      );
      await AnalyticsService.instance.logExportPdf(topic);
      // Best-effort: record the export + a `reports` document for the web admin
      // (fire-and-forget so a Firestore failure can't fail the export).
      unawaited(UserDataService.instance.recordExport(
        topic: topic,
        fileName: fileName,
        downloadUrl: url,
      ));
    } catch (e) {
      exportError = e.toString();
    } finally {
      // The report is a temp file — remove it whether the upload succeeded or
      // failed so it doesn't accumulate in the temporary directory.
      if (file != null) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }

    exporting = false;
    notifyListeners();
  }

  /// Records a successful export, newest first, capped at [maxHistory].
  /// Dropping the oldest entry only removes the local record — the file stays
  /// in Firebase Storage.
  Future<void> _addToHistory(ExportedReport report) => _serializeHistory(() async {
        _history.insert(0, report);
        if (_history.length > maxHistory) {
          _history = _history.sublist(0, maxHistory);
        }
        await _historyStorage.save(_history);
      });

  /// Removes one entry from the local history only; the file in Storage is
  /// left untouched.
  Future<void> removeFromHistory(ExportedReport report) =>
      _serializeHistory(() async {
        _history.removeWhere(
          (r) => r.url == report.url && r.exportedAt == report.exportedAt,
        );
        notifyListeners();
        await _historyStorage.save(_history);
      });
}
