import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final response = await dio.get(
    'https://api.openalex.org/works',
    queryParameters: {
      'search': 'iot',
      'per-page': 200,
      'sort': 'cited_by_count:desc',
    },
  );
  
  final results = response.data['results'] as List;
  print('Total results: ${results.length}');
  int journalCount = 0;
  for (var r in results) {
    final j = r['primary_location']?['source']?['display_name'];
    if (j != null && j.toString().trim().isNotEmpty) {
      journalCount++;
    }
  }
  print('Results with journals: $journalCount');
}
