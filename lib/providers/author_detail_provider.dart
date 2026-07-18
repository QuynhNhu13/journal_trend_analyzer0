import 'package:flutter/material.dart';
import '../models/author.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';
import '../utils/async_utils.dart';

class AuthorDetailProvider extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService();

  AuthorDetail? author;
  List<Publication> publications = [];
  
  bool isLoading = false;
  String errorMessage = "";

  Future<void> fetchDetail(String authorId, String topic) async {
    try {
      isLoading = true;
      errorMessage = "";
      author = null;
      publications = [];
      notifyListeners();

      // PRIMARY: the author detail IS the page — failure ⇒ error state (+ retry).
      // Their publications are enrichment: degrade to empty so a hiccup there
      // can't error the whole screen (endless error → retry loop).
      final authorFuture = _service.fetchAuthorDetail(authorId);
      final pubsFuture = orFallback(
          _service.fetchAuthorPublications(authorId: authorId, topic: topic),
          const <Publication>[]);

      author = await authorFuture;
      publications = await pubsFuture;
    } catch (e) {
      errorMessage = "Error: $e";
      author = null;
      publications = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void reset() {
    isLoading = false;
    errorMessage = "";
    author = null;
    publications = [];
    notifyListeners();
  }
}
