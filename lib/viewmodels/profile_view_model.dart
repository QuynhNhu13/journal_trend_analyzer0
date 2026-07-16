import 'dart:io';

import 'package:flutter/foundation.dart';

import '../firebase/analytics_service.dart';
import '../firebase/storage_service.dart';
import '../models/dashboard_summary.dart';
import '../utils/pdf_report_service.dart';

/// ViewModel for the Profile screen's Report Export flow (lab §4.8):
/// build a PDF → upload to Firebase Storage → expose the download URL.
class ProfileViewModel extends ChangeNotifier {
  bool exporting = false;
  String? reportUrl;
  String? exportError;

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
      await AnalyticsService.instance.logExportPdf(topic);
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
}
