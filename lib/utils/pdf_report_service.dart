import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/dashboard_summary.dart';
import '../models/publication.dart';

/// Builds a PDF analytics report from the current dashboard data (lab §4.8
/// "Report Export"). Returns the saved [File] so it can be uploaded to Storage.
///
/// The report copy is intentionally **fixed English**, not localized: the PDF
/// is a shareable academic artefact and the OpenAlex data it wraps (titles,
/// journal and author names) is English anyway, so a single language keeps
/// every exported file consistent regardless of the app's UI locale. A Unicode
/// font is still loaded because that OpenAlex data can contain non-ASCII
/// characters.
class PdfReportService {
  PdfReportService._();
  static final PdfReportService instance = PdfReportService._();

  /// Widest trend window drawn on the chart, in years.
  static const int _maxTrendYears = 30;

  /// Rows in the appendix table (most recent years).
  static const int _appendixYears = 10;

  Future<File> buildDashboardReport({
    required String topic,
    required ResearchDashboardSummary summary,
  }) async {
    final doc = pw.Document();
    final rose = PdfColor.fromHex('#DB2777');

    // The default base-14 PDF fonts (Helvetica) can't render Vietnamese
    // diacritics, so load a Unicode-capable font and apply it via the page
    // theme so every pw.Text/Bullet/TableHelper renders correctly.
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);

    final allYears = _sanitizedTrend(summary.publicationTrend);
    final chartYears = _trendWindow(allYears);
    final appendixYears = allYears.length <= _appendixYears
        ? allYears
        : allYears.sublist(allYears.length - _appendixYears);

    doc.addPage(
      pw.MultiPage(
        theme: theme,
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
                pw.Text('Research trend analytics report',
                    style: const pw.TextStyle(
                        color: PdfColors.white, fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Topic: $topic',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('Generated at: ${DateTime.now()}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),

          // KPI table
          pw.Text('Overview Metrics',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#FCE7F3')),
            headers: ['Metric', 'Value'],
            data: [
              ['Total publications', '${summary.totalPublications}'],
              ['Average citations',
                  summary.averageCitationCount.toStringAsFixed(1)],
              ['Most active year', '${summary.mostActiveYear ?? "N/A"}'],
              ['Top journal', summary.topJournal ?? 'N/A'],
              ['Top author', summary.topAuthor ?? 'N/A'],
              ['Papers retrieved', '${summary.papersRetrieved}'],
            ],
          ),
          pw.SizedBox(height: 20),

          // Most influential paper
          if (summary.mostInfluentialPaper != null) ...[
            pw.Text('Most Influential Publication',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Bullet(text: summary.mostInfluentialPaper!.title),
            pw.Text(
                'Citations: ${summary.mostInfluentialPaper!.citationCount} · '
                'Year: ${summary.mostInfluentialPaper!.year}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
          ],

          // Trend chart
          pw.Text('Publication Trend by Year',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ..._trendSection(chartYears, rose),

          // Appendix
          if (appendixYears.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text(
                'Appendix — Publications per Year (last ${appendixYears.length})',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#FCE7F3')),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headers: ['Year', 'Publications'],
              data: appendixYears
                  .map((t) => ['${t.year}', '${t.count}'])
                  .toList(),
            ),
          ],
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount} · Data: OpenAlex',
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

  // ─── Trend chart ─────────────────────────────────────────

  /// The chart plus its range/source caption, or a fallback line when there is
  /// nothing meaningful to plot.
  List<pw.Widget> _trendSection(List<PublicationTrendPoint> points, PdfColor rose) {
    if (points.isEmpty) {
      return [pw.Text('No trend data available.')];
    }
    // A line needs at least two points; a single year is reported as text.
    if (points.length < 2) {
      final only = points.single;
      return [
        pw.Text('${only.count} publication(s) in ${only.year}.'),
        pw.SizedBox(height: 4),
        _caption(points),
      ];
    }

    final firstYear = points.first.year;
    final lastYear = points.last.year;
    final maxCount = points.map((t) => t.count).reduce(math.max);
    final axisStyle =
        const pw.TextStyle(fontSize: 8, color: PdfColors.grey700);
    final labelStyle = pw.TextStyle(
        fontSize: 9, color: PdfColors.grey800, fontWeight: pw.FontWeight.bold);

    return [
      pw.SizedBox(
        height: 190,
        child: pw.Chart(
          left: pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Transform.rotateBox(
              angle: math.pi / 2,
              child: pw.Text('Publications', style: labelStyle),
            ),
          ),
          bottom: pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 4),
            child: pw.Text('Year', style: labelStyle),
          ),
          grid: pw.CartesianGrid(
            xAxis: pw.FixedAxis(
              _xTicks(firstYear, lastYear),
              format: (v) => v.toInt().toString(),
              textStyle: axisStyle,
              divisions: true,
              divisionsColor: PdfColors.grey300,
            ),
            yAxis: pw.FixedAxis(
              _yTicks(maxCount),
              format: (v) => v.toInt().toString(),
              textStyle: axisStyle,
              divisions: true,
              divisionsColor: PdfColors.grey300,
            ),
          ),
          datasets: [
            pw.LineDataSet(
              data: points
                  .map((t) =>
                      pw.PointChartValue(t.year.toDouble(), t.count.toDouble()))
                  .toList(),
              color: rose,
              lineWidth: 1.5,
              // Point markers only stay legible on a short window.
              drawPoints: points.length <= 15,
              pointSize: 1.8,
              pointColor: rose,
              drawSurface: true,
              surfaceColor: rose,
              surfaceOpacity: 0.15,
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
      _caption(points),
    ];
  }

  pw.Widget _caption(List<PublicationTrendPoint> points) => pw.Text(
        'Data ${points.first.year}–${points.last.year} · Source: OpenAlex',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );

  /// Drops out-of-range years and sorts ascending.
  List<PublicationTrendPoint> _sanitizedTrend(List<PublicationTrendPoint> raw) {
    final currentYear = DateTime.now().year;
    return raw.where((t) => t.year >= 1900 && t.year <= currentYear).toList()
      ..sort((a, b) => a.year.compareTo(b.year));
  }

  /// Picks the window worth plotting.
  ///
  /// OpenAlex returns a long, near-empty tail (single papers back to 1900) that
  /// squashes the meaningful recent years into the right edge of the chart. So
  /// we start at the first year contributing at least 1% of all publications,
  /// and additionally cap the window at [_maxTrendYears] so a topic with a long
  /// significant history still produces a readable chart. Every year inside the
  /// window is kept, including quiet ones, so the line stays continuous.
  List<PublicationTrendPoint> _trendWindow(List<PublicationTrendPoint> sorted) {
    if (sorted.isEmpty) return const [];

    final total = sorted.fold<int>(0, (sum, t) => sum + t.count);
    final threshold = total * 0.01;
    final lastYear = sorted.last.year;

    final firstSignificant = sorted
        .firstWhere((t) => t.count >= threshold, orElse: () => sorted.first)
        .year;
    final start = math.max(firstSignificant, lastYear - (_maxTrendYears - 1));

    return sorted.where((t) => t.year >= start).toList();
  }

  /// X ticks across [first]..[last]; both ends are always included so no data
  /// point falls outside the axis range.
  List<double> _xTicks(int first, int last) {
    const desired = 6;
    final span = last - first;
    final step = math.max(1, (span / (desired - 1)).ceil());

    final ticks = <double>[];
    for (var y = first; y <= last; y += step) {
      ticks.add(y.toDouble());
    }
    if (ticks.last != last.toDouble()) {
      // Avoid a cramped label right next to the final tick.
      if (last - ticks.last.toInt() < step / 2 && ticks.length > 1) {
        ticks.removeLast();
      }
      ticks.add(last.toDouble());
    }
    return ticks;
  }

  /// Y ticks from 0 up to at least [maxCount], on a 1/2/5×10ⁿ step.
  List<double> _yTicks(int maxCount) {
    if (maxCount <= 0) return [0, 1];
    const desired = 4;
    final step = _niceStep(maxCount / desired);

    final ticks = <double>[];
    for (var v = 0.0; v < maxCount + step; v += step) {
      ticks.add(v);
    }
    return ticks;
  }

  /// Rounds [raw] up to the nearest "nice" axis step (1, 2, 5 × a power of 10).
  double _niceStep(double raw) {
    if (raw <= 1) return 1;
    final exponent = (math.log(raw) / math.ln10).floor();
    final pow10 = math.pow(10, exponent).toDouble();
    final fraction = raw / pow10;
    final double nice;
    if (fraction <= 1) {
      nice = 1;
    } else if (fraction <= 2) {
      nice = 2;
    } else if (fraction <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * pow10;
  }
}
