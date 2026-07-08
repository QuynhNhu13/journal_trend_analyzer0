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
    exporting = true;
    reportUrl = null;
    exportError = null;
    notifyListeners();

    try {
      final file = await PdfReportService.instance
          .buildDashboardReport(topic: topic, summary: summary);
      final fileName = file.uri.pathSegments.last;
      final url = await StorageService.instance.uploadReport(file, fileName);
      reportUrl = url;
      await AnalyticsService.instance.logExportPdf(topic);
    } catch (e) {
      exportError = e.toString();
    }

    exporting = false;
    notifyListeners();
  }
}
