/// One entry in the local "Exported reports" history (lab §4.8).
///
/// Records a PDF report that was successfully built and uploaded to Firebase
/// Storage. History is local-only: deleting an entry never touches the file in
/// the bucket.
class ExportedReport {
  final String topic;
  final String fileName;
  final String url;
  final DateTime exportedAt;

  const ExportedReport({
    required this.topic,
    required this.fileName,
    required this.url,
    required this.exportedAt,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'fileName': fileName,
        'url': url,
        'exportedAt': exportedAt.toIso8601String(),
      };

  /// Returns null when a persisted entry is malformed (e.g. written by an older
  /// build) so a single bad record can't break the whole history.
  static ExportedReport? fromJson(Map<String, dynamic> json) {
    final url = json['url']?.toString();
    final exportedAt = DateTime.tryParse(json['exportedAt']?.toString() ?? '');
    if (url == null || url.isEmpty || exportedAt == null) return null;

    return ExportedReport(
      topic: json['topic']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      url: url,
      exportedAt: exportedAt,
    );
  }
}
