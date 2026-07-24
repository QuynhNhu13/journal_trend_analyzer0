class Publication {
  final String title;
  final int year;
  final int citationCount;
  final String doi;
  final String journal;
  final String issn;
  final List<String> authors;
  final String abstractText;
  
  // New fields
  final String type;
  final List<String> institutions;
  final String language;
  final double fwci;
  final int cites;
  final int relatedTo;
  final String topic;
  final String subfield;
  final String field;
  final String domain;
  final String sdg;
  final String openAccessStatus;
  final List<String> funders;
  final List<String> awards;

  Publication({
    required this.title,
    required this.year,
    required this.citationCount,
    required this.doi,
    required this.journal,
    this.issn = "",
    required this.authors,
    required this.abstractText,
    this.type = "",
    this.institutions = const [],
    this.language = "",
    this.fwci = 0.0,
    this.cites = 0,
    this.relatedTo = 0,
    this.topic = "",
    this.subfield = "",
    this.field = "",
    this.domain = "",
    this.sdg = "",
    this.openAccessStatus = "",
    this.funders = const [],
    this.awards = const [],
  });

  factory Publication.fromJson(Map<String,dynamic> json){
    List<String> parsedAuthors = [];
    List<String> parsedInstitutions = [];
    
    if (json['authorships'] != null) {
      for (var authorData in json['authorships']) {
        if (authorData['author'] != null && authorData['author']['display_name'] != null) {
          parsedAuthors.add(authorData['author']['display_name']);
        }
        if (authorData['institutions'] != null) {
          for (var inst in authorData['institutions']) {
            if (inst['display_name'] != null) {
              if (!parsedInstitutions.contains(inst['display_name'])) {
                parsedInstitutions.add(inst['display_name']);
              }
            }
          }
        }
      }
    }
    
    String reconstructedAbstract = "";
    if (json['abstract_inverted_index'] != null) {
      Map<String, dynamic> indexMap = json['abstract_inverted_index'];
      Map<int, String> wordsMap = {};
      indexMap.forEach((word, positions) {
        for (var pos in positions) {
          wordsMap[pos] = word;
        }
      });
      var sortedKeys = wordsMap.keys.toList()..sort();
      reconstructedAbstract = sortedKeys.map((k) => wordsMap[k]).join(" ");
    }

    double parsedFwci = 0.0;
    if (json['fwci'] != null) {
      parsedFwci = (json['fwci'] is int) ? (json['fwci'] as int).toDouble() : json['fwci'];
    }

    int parsedCites = json['referenced_works_count'] ?? 0;
    int parsedRelatedTo = 0;
    if (json['related_works'] != null) {
      parsedRelatedTo = (json['related_works'] as List).length;
    }

    String parsedTopic = json['primary_topic']?['display_name'] ?? "";
    String parsedSubfield = json['primary_topic']?['subfield']?['display_name'] ?? "";
    String parsedField = json['primary_topic']?['field']?['display_name'] ?? "";
    String parsedDomain = json['primary_topic']?['domain']?['display_name'] ?? "";

    String parsedSdg = "";
    if (json['sustainable_development_goals'] != null && (json['sustainable_development_goals'] as List).isNotEmpty) {
      parsedSdg = json['sustainable_development_goals'][0]['display_name'] ?? "";
    }

    String parsedOaStatus = json['open_access']?['oa_status'] ?? "";

    List<String> parsedFunders = [];
    List<String> parsedAwards = [];
    if (json['grants'] != null) {
      for (var grant in json['grants']) {
        if (grant['funder_display_name'] != null && !parsedFunders.contains(grant['funder_display_name'])) {
          parsedFunders.add(grant['funder_display_name']);
        }
        if (grant['award_id'] != null && !parsedAwards.contains(grant['award_id'])) {
          parsedAwards.add(grant['award_id']);
        }
      }
    }

    return Publication(
      title: json['title'] ?? "",
      year: json['publication_year'] ?? 0,
      citationCount: json['cited_by_count'] ?? 0,
      doi: json['doi'] ?? "",
      journal: json['primary_location']?['source']?['display_name'] ?? "",
      issn: json['primary_location']?['source']?['issn_l']?.toString() ?? "",
      authors: parsedAuthors,
      abstractText: reconstructedAbstract,
      type: json['type'] ?? "",
      institutions: parsedInstitutions,
      language: json['language'] ?? "",
      fwci: parsedFwci,
      cites: parsedCites,
      relatedTo: parsedRelatedTo,
      topic: parsedTopic,
      subfield: parsedSubfield,
      field: parsedField,
      domain: parsedDomain,
      sdg: parsedSdg,
      openAccessStatus: parsedOaStatus,
      funders: parsedFunders,
      awards: parsedAwards,
    );
  }
}

class PublicationTrendPoint {
  final int year;
  final int count;

  PublicationTrendPoint({
    required this.year,
    required this.count,
  });

  factory PublicationTrendPoint.fromJson(Map<String, dynamic> json) {
    int year = 0;
    if (json['key'] != null) {
      year = int.tryParse(json['key'].toString()) ?? 0;
    }
    return PublicationTrendPoint(
      year: year,
      count: json['count'] ?? 0,
    );
  }
}