import 'package:dio/dio.dart';

import '../models/publication.dart';
import '../models/author.dart';
import '../models/dashboard_summary.dart';

class OpenAlexService{

  final Dio dio=Dio(
    BaseOptions(
      connectTimeout: Duration(seconds:10),
      receiveTimeout: Duration(seconds:10)
    )
  );

  // Shared author name filter
  static bool _isValidAuthorName(String name) {
    String lowerName = name.toLowerCase().trim();
    if (name.isEmpty || lowerName == "unknown" || lowerName == "null" || lowerName == "n/a" || lowerName == "anonymous") {
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
      final response= await dio.get('https://api.openalex.org/works?search=$keyword&per-page=200');
      List results= response.data['results'];
      return results.map((e)=> Publication.fromJson(e)).toList();
    }catch(e){
      throw Exception("API Failed");
    }
  }

  Future<List<PublicationTrendPoint>> fetchPublicationTrend(String keyword) async{
    try{
      final response= await dio.get('https://api.openalex.org/works?search=$keyword&group_by=publication_year');
      List results= response.data['group_by'];
      return results.map((e)=> PublicationTrendPoint.fromJson(e)).toList();
    }catch(e){
      throw Exception("Trend API Failed");
    }
  }

  Future<List<Publication>> fetchTopInfluentialPapers(String keyword) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works?search=$keyword&sort=cited_by_count:desc&per-page=20'
      );
      List results = response.data['results'];
      return results.map((e) => Publication.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Top Papers API Failed");
    }
  }

  Future<List<TopAuthor>> fetchTopAuthors(String keyword) async {
    try {
      final response = await dio.get('https://api.openalex.org/works?search=$keyword&group_by=authorships.author.id');
      List results = response.data['group_by'];
      
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
        'https://api.openalex.org/works?filter=authorships.author.id:$authorId&search=$topic&sort=cited_by_count:desc&per-page=25'
      );
      List results = response.data['results'];
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
        'https://api.openalex.org/works?search=$keyword&group_by=keywords.id',
      );
      List results = response.data['group_by'];
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

  Future<int> fetchTotalPublicationCount(String keyword) async {
    try {
      final response = await dio.get('https://api.openalex.org/works?search=$keyword&per-page=1');
      return response.data['meta']?['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<String?> fetchTopJournal(String keyword) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works?search=$keyword&group_by=primary_location.source.id'
      );
      List results = response.data['group_by'];
      if (results.isNotEmpty) {
        return results[0]['key_display_name']?.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> fetchDashboardTopAuthor(String keyword) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works?search=$keyword&group_by=authorships.author.id'
      );
      List results = response.data['group_by'];
      for (var entry in results) {
        String name = entry['key_display_name']?.toString().trim() ?? "";
        if (_isValidAuthorName(name)) {
          return name;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Publication?> fetchMostInfluentialPaper(String keyword) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works?search=$keyword&sort=cited_by_count:desc&per-page=1'
      );
      List results = response.data['results'];
      if (results.isNotEmpty) {
        return Publication.fromJson(results[0]);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetches up to [limit] papers and returns both the average citation count
  /// and the real number of papers retrieved (`results.length`, which may be
  /// less than [limit] when fewer matching works exist).
  Future<({double avg, int count})> fetchCitationStats(
      String keyword, int limit) async {
    try {
      final response = await dio.get(
        'https://api.openalex.org/works?search=$keyword&sort=cited_by_count:desc&per-page=$limit'
      );
      List results = response.data['results'];
      if (results.isEmpty) return (avg: 0.0, count: 0);
      int totalCitations = 0;
      for (var r in results) {
        totalCitations += (r['cited_by_count'] as int?) ?? 0;
      }
      return (avg: totalCitations / results.length, count: results.length);
    } catch (e) {
      return (avg: 0.0, count: 0);
    }
  }

  Future<ResearchDashboardSummary> fetchResearchDashboardSummary(String keyword, int limit) async {
    var futures = await Future.wait([
      fetchTotalPublicationCount(keyword),      // 0
      fetchPublicationTrend(keyword),            // 1
      fetchTopJournal(keyword),                  // 2
      fetchDashboardTopAuthor(keyword),          // 3
      fetchMostInfluentialPaper(keyword),         // 4
      fetchCitationStats(keyword, limit),         // 5
    ]);

    int totalPublications = futures[0] as int;
    List<PublicationTrendPoint> trend = futures[1] as List<PublicationTrendPoint>;
    String? topJournal = futures[2] as String?;
    String? topAuthor = futures[3] as String?;
    Publication? mostInfluential = futures[4] as Publication?;
    final citationStats = futures[5] as ({double avg, int count});
    double avgCitations = citationStats.avg;
    int papersRetrieved = citationStats.count;

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
      totalPublications: totalPublications,
      averageCitationCount: avgCitations,
      mostActiveYear: mostActiveYear,
      topJournal: topJournal,
      topAuthor: topAuthor,
      mostInfluentialPaper: mostInfluential,
      publicationTrend: trend,
      papersRetrieved: papersRetrieved,
    );
  }
}