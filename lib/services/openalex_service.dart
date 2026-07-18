import 'package:dio/dio.dart';

import '../models/publication.dart';
import '../models/author.dart';
import '../models/dashboard_summary.dart';

class OpenAlexService{

  /// Shared instance so ViewModels reuse one service (and one Dio client)
  /// instead of each constructing their own.
  static final OpenAlexService instance = OpenAlexService();

  final Dio dio=Dio(
    BaseOptions(
      connectTimeout: Duration(seconds:10),
      receiveTimeout: Duration(seconds:10)
    )
  );

  /// Returns the JSON list at [value], or THROWS when it is missing / not a
  /// list.
  ///
  /// OpenAlex always returns `results` / `group_by` as a list on a genuine
  /// success — an empty list when there are simply no matches. A non-list here
  /// means the request did NOT really succeed: an error object, a rate-limit
  /// body, or a malformed payload returned with a 2xx status. We MUST surface
  /// that as a failure. Returning an empty list (the previous behaviour) would
  /// disguise a network/API error as a legitimate "no results" and mislead the
  /// user — the exact bug the empty-vs-error UI distinction must avoid.
  static List _requireList(dynamic value) {
    if (value is List) return value;
    throw Exception('Unexpected OpenAlex response (expected a list)');
  }

  /// Awaits [future], returning [fallback] if it fails.
  ///
  /// Used for the dashboard's AUXILIARY (enrichment) requests. The dashboard
  /// fans out several parallel calls; a hiccup in one of them must NOT turn a
  /// working search into an error — otherwise the UI flips to the error state
  /// and the test's auto-retry keeps re-searching endlessly. Success vs failure
  /// is decided solely by the PRIMARY request (see [fetchResearchDashboardSummary]).
  static Future<T> _orFallback<T>(Future<T> future, T fallback) async {
    try {
      return await future;
    } catch (_) {
      return fallback;
    }
  }

  // Shared author name filter
  static bool _isValidAuthorName(String name) {
    String lowerName = name.toLowerCase().trim();
    if (lowerName.isEmpty || lowerName == "unknown" || lowerName == "null" || lowerName == "n/a" || lowerName == "anonymous") {
      return false;
    }
    const invalidPatterns = [
      "certification exam", "www.", ".com", ".org", "chatterbox",
      "gemini", "chatgpt", "openai", "gpt-4", "gpt-3", "claude",
      "copilot", "llama", "midjourney", "dall-e", "bard",
    ];
    for (var pattern in invalidPatterns) {
      if (lowerName.contains(pattern)) return false;
    }
    if (lowerName.startsWith("http")) return false;
    if (lowerName == "gpt") return false;
    return true;
  }

  Future<List<Publication>> searchPublication(String keyword) async{
    try{
      final response = await dio.get(
        'https://api.openalex.org/works',
        queryParameters: {'search': keyword, 'per-page': 200},
      );
      final results = _requireList(response.data['results']);
      return results.map((e) => Publication.fromJson(e)).toList();
    }catch(e){
      throw Exception("API Failed");
    }
  }

  Future<List<PublicationTrendPoint>> fetchPublicationTrend(String keyword) async{
    try{
      final response = await dio.get(
        'https://api.openalex.org/works',
        queryParameters: {'search': keyword, 'group_by': 'publication_year'},
      );
      final results = _requireList(response.data['group_by']);
      return results.map((e) => PublicationTrendPoint.fromJson(e)).toList();
    }catch(e){
      throw Exception("Trend API Failed");
    }
  }

  Future<List<Publication>> fetchTopInfluentialPapers(String keyword) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works',
        queryParameters: {
          'search': keyword,
          'sort': 'cited_by_count:desc',
          'per-page': 20,
        },
      );
      final results = _requireList(response.data['results']);
      return results.map((e) => Publication.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Top Papers API Failed");
    }
  }

  Future<List<TopAuthor>> fetchTopAuthors(String keyword) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works',
        queryParameters: {
          'search': keyword,
          'group_by': 'authorships.author.id',
        },
      );
      final results = _requireList(response.data['group_by']);

      Map<String, TopAuthor> mergedAuthors = {};
      
      for (var e in results) {
        String name = e['key_display_name']?.toString().trim() ?? "Unknown";
        int count = e['count'] as int? ?? 0;
        
        if (!_isValidAuthorName(name)) continue;
        
        if (mergedAuthors.containsKey(name)) {
          // If we see duplicate names with different IDs, just combine their count.
          mergedAuthors[name] = TopAuthor(
            id: mergedAuthors[name]!.id,
            name: name,
            worksCount: mergedAuthors[name]!.worksCount + count,
            citedByCount: null,
          );
        } else {
          mergedAuthors[name] = TopAuthor.fromJson(e);
        }
      }
      
      var mergedList = mergedAuthors.values.toList();
      mergedList.sort((a, b) => b.worksCount.compareTo(a.worksCount));
      
      return mergedList;
    } catch (e) {
      throw Exception("Top Authors API Failed");
    }
  }

  Future<AuthorDetail> fetchAuthorDetail(String authorId) async {
    try {
      final response = await dio.get('https://api.openalex.org/authors/$authorId');
      return AuthorDetail.fromJson(response.data);
    } catch (e) {
      throw Exception("Author Detail API Failed");
    }
  }

  Future<List<Publication>> fetchAuthorPublications({
    required String authorId,
    required String topic,
  }) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works',
        queryParameters: {
          'filter': 'authorships.author.id:$authorId',
          'search': topic,
          'sort': 'cited_by_count:desc',
          'per-page': 25,
        },
      );
      final results = _requireList(response.data['results']);
      return results.map((e) => Publication.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Author Publications API Failed");
    }
  }

  /// Aggregates the most frequent keywords for a topic using OpenAlex's
  /// `group_by=keywords.id`. Returns (keyword, count) sorted descending.
  Future<List<MapEntry<String, int>>> fetchTopKeywords(String keyword) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works',
        queryParameters: {
          'search': keyword,
          'group_by': 'keywords.id',
        },
      );
      final results = _requireList(response.data['group_by']);
      final entries = <MapEntry<String, int>>[];
      for (var e in results) {
        final name = e['key_display_name']?.toString().trim() ?? '';
        final count = e['count'] as int? ?? 0;
        if (name.isEmpty || name.toLowerCase() == 'unknown') continue;
        entries.add(MapEntry(name, count));
      }
      entries.sort((a, b) => b.value.compareTo(a.value));
      return entries;
    } catch (e) {
      throw Exception('Top Keywords API Failed');
    }
  }

  // Dashboard-specific API methods

  Future<String?> fetchTopJournal(String keyword) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works',
        queryParameters: {
          'search': keyword,
          'group_by': 'primary_location.source.id',
        },
      );
      final results = _requireList(response.data['group_by']);
      if (results.isNotEmpty) {
        return results[0]['key_display_name']?.toString();
      }
      return null; // request OK, simply no journal data
    } catch (e) {
      throw Exception('Top Journal API Failed');
    }
  }

  Future<String?> fetchDashboardTopAuthor(String keyword) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works',
        queryParameters: {
          'search': keyword,
          'group_by': 'authorships.author.id',
        },
      );
      final results = _requireList(response.data['group_by']);
      for (var entry in results) {
        String name = entry['key_display_name']?.toString().trim() ?? "";
        if (_isValidAuthorName(name)) {
          return name;
        }
      }
      return null; // request OK, no valid author found
    } catch (e) {
      throw Exception('Dashboard Top Author API Failed');
    }
  }

  /// The dashboard's single AUTHORITATIVE request. One `works` call sorted by
  /// citations yields everything that decides success/empty plus the headline
  /// result, all from the same response:
  ///   • `meta.count`    → total matching publications (0 ⇒ empty state),
  ///   • `results`       → papers actually retrieved (for avg citations + count),
  ///   • `results.first` → the most-influential paper (drives the "Most
  ///                        Influential" card and its Details button).
  ///
  /// Throws on a real failure so the UI shows the error state. Deriving the
  /// most-influential paper from THIS response (instead of a separate,
  /// independently-degradable fetch) guarantees the card + Details entry point
  /// always render whenever the search returned papers — a separate call could
  /// drop the paper (and the button) on a successful search and break the flow.
  Future<({int total, double avg, int count, Publication? mostInfluential})>
      _fetchCoreResults(String keyword, int limit) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works',
        queryParameters: {
          'search': keyword,
          'sort': 'cited_by_count:desc',
          'per-page': limit,
        },
      );
      final total = response.data['meta']?['count'];
      // A genuine success always carries an integer meta.count (0 when there are
      // no matches). Its absence means the response is not a real success.
      if (total is! int) {
        throw Exception('Unexpected OpenAlex response (missing meta.count)');
      }
      final results = _requireList(response.data['results']);
      if (results.isEmpty) {
        return (total: total, avg: 0.0, count: 0, mostInfluential: null);
      }
      int totalCitations = 0;
      for (var r in results) {
        totalCitations += (r['cited_by_count'] as int?) ?? 0;
      }
      return (
        total: total,
        avg: totalCitations / results.length,
        count: results.length,
        mostInfluential: Publication.fromJson(results[0]),
      );
    } catch (e) {
      throw Exception('Search API Failed');
    }
  }

  Future<ResearchDashboardSummary> fetchResearchDashboardSummary(String keyword, int limit) async {
    // Enrichment requests: degrade to a safe default on failure so a flaky
    // secondary call can't error the whole dashboard (which trapped the UI in an
    // endless error → retry loop). They never affect the success/empty decision.
    final trendFuture = _orFallback<List<PublicationTrendPoint>>(
        fetchPublicationTrend(keyword), const []);
    final topJournalFuture =
        _orFallback<String?>(fetchTopJournal(keyword), null);
    final topAuthorFuture =
        _orFallback<String?>(fetchDashboardTopAuthor(keyword), null);

    // PRIMARY signal — ONE authoritative request (mirrors how Journals/Keywords
    // rely on a single call). It throws on real failure (⇒ error state + retry)
    // and returns total count, retrieved papers AND the most-influential paper
    // together, so the "Most Influential" card + its Details button always
    // render whenever the search returned results.
    //   • throws     → search genuinely failed ⇒ error state, not a fake "empty".
    //   • total == 0 → search OK but the topic has no papers ⇒ empty state.
    final core = await _fetchCoreResults(keyword, limit);

    final trend = await trendFuture;
    final topJournal = await topJournalFuture;
    final topAuthor = await topAuthorFuture;

    // Most active year from trend data
    int? mostActiveYear;
    int maxCount = 0;
    for (var point in trend) {
      if (point.year >= 1900 && point.count > maxCount) {
        maxCount = point.count;
        mostActiveYear = point.year;
      }
    }

    return ResearchDashboardSummary(
      totalPublications: core.total,
      averageCitationCount: core.avg,
      mostActiveYear: mostActiveYear,
      topJournal: topJournal,
      topAuthor: topAuthor,
      mostInfluentialPaper: core.mostInfluential,
      publicationTrend: trend,
      papersRetrieved: core.count,
    );
  }
}