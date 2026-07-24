import 'publication.dart';

/// Aggregated statistics for one journal within a topic's result set
/// (lab §4.4 Journals, §4.5 Journal Details).
class JournalStat {
  final String name;
  final String issn;
  final int publicationCount;
  final int totalCitations;
  final List<Publication> publications;

  JournalStat({
    required this.name,
    required this.issn,
    required this.publicationCount,
    required this.totalCitations,
    required this.publications,
  });

  double get averageCitations =>
      publicationCount == 0 ? 0 : totalCitations / publicationCount;
}
