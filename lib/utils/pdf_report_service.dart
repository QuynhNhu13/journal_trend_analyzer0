import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/dashboard_summary.dart';

/// Builds a PDF analytics report from the current dashboard data (lab §4.8
/// "Report Export"). Returns the saved [File] so it can be uploaded to Storage.
class PdfReportService {
  PdfReportService._();
  static final PdfReportService instance = PdfReportService._();

  Future<File> buildDashboardReport({
    required String topic,
    required ResearchDashboardSummary summary,
  }) async {
    final doc = pw.Document();
    final rose = PdfColor.fromHex('#DB2777');

    final trend = summary.publicationTrend
        .where((t) => t.year >= 1900 && t.year <= DateTime.now().year)
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: rose,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Journal Trend Analyzer',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Báo cáo phân tích xu hướng nghiên cứu',
                    style: const pw.TextStyle(
                        color: PdfColors.white, fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Chủ đề: $topic',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('Tạo lúc: ${DateTime.now()}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),

          // KPI table
          pw.Text('Chỉ số tổng quan',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#FCE7F3')),
            headers: ['Chỉ số', 'Giá trị'],
            data: [
              ['Tổng số công bố', '${summary.totalPublications}'],
              ['Trung bình trích dẫn',
                  summary.averageCitationCount.toStringAsFixed(1)],
              ['Năm sôi động nhất', '${summary.mostActiveYear ?? "N/A"}'],
              ['Tạp chí hàng đầu', summary.topJournal ?? 'N/A'],
              ['Tác giả hàng đầu', summary.topAuthor ?? 'N/A'],
              ['Số papers lấy về', '${summary.papersRetrieved}'],
            ],
          ),
          pw.SizedBox(height: 20),

          // Most influential paper
          if (summary.mostInfluentialPaper != null) ...[
            pw.Text('Công bố ảnh hưởng nhất',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Bullet(text: summary.mostInfluentialPaper!.title),
            pw.Text(
                'Trích dẫn: ${summary.mostInfluentialPaper!.citationCount} · '
                'Năm: ${summary.mostInfluentialPaper!.year}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
          ],

          // Trend table
          pw.Text('Xu hướng công bố theo năm',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (trend.isEmpty)
            pw.Text('Không có dữ liệu xu hướng.')
          else
            pw.TableHelper.fromTextArray(
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#FCE7F3')),
              headers: ['Năm', 'Số công bố'],
              data: trend.map((t) => ['${t.year}', '${t.count}']).toList(),
            ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Trang ${context.pageNumber}/${context.pagesCount} · Dữ liệu: OpenAlex',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final safeTopic =
        topic.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase();
    final fileName =
        'report_${safeTopic}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }
}
