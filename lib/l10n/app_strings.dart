import 'locale_provider.dart';

/// Central catalogue of every user-facing UI string in both English and
/// Vietnamese.
///
/// Each entry keeps the English and Vietnamese text side by side via [_t], so
/// adding or editing copy means touching a single line. Only UI chrome lives
/// here — buttons, titles, labels, menus, filters, error and loading messages.
/// Academic data from OpenAlex (paper titles, abstracts, journal/author names,
/// DOIs, topic/field values, etc.) is intentionally NOT translated.
class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  /// Picks the English or Vietnamese variant for the active language.
  String _t(String en, String vi) => lang == AppLanguage.vi ? vi : en;

  // ─── Shared ──────────────────────────────────────────────
  String get appTitle => _t('Journal Trend Analyzer', 'Phân tích Xu hướng Tạp chí');
  String get somethingWentWrong => _t('Something went wrong', 'Đã xảy ra lỗi');
  String get tryAgain => _t('Try again', 'Thử lại');
  String get papersUnit => _t('papers', 'bài báo');
  String get notAvailable => _t('N/A', 'Không có');
  String get languageMenu => _t('Language', 'Ngôn ngữ');
  String get clearAll => _t('Clear all', 'Xóa tất cả');
  String get recentSearchesTitle => _t('Recent searches', 'Tìm kiếm gần đây');
  String get recentComparisonsTitle =>
      _t('Recent comparisons', 'So sánh gần đây');

  // ─── Search screen ───────────────────────────────────────
  String get searchHeaderSubtitle => _t(
      'Explore research trends with OpenAlex',
      'Khám phá xu hướng nghiên cứu với OpenAlex');
  String get enterTopicWarning =>
      _t('Please enter a research topic', 'Vui lòng nhập chủ đề nghiên cứu');
  String get searchHint =>
      _t('Search a research topic…', 'Tìm kiếm chủ đề nghiên cứu…');
  String get analyzingPublications =>
      _t('Analyzing publications…', 'Đang phân tích các công bố…');
  String get emptyStateTitle =>
      _t('Start exploring research', 'Bắt đầu khám phá nghiên cứu');
  String get emptyStateMessage => _t(
      'Search a topic to analyze publications, citations, journals and authors.',
      'Tìm một chủ đề để phân tích công bố, trích dẫn, tạp chí và tác giả.');
  String get exploreInsights => _t('Explore insights', 'Khám phá thông tin');

  /// "{count} results for "{topic}""
  String resultsFor(int count, String topic) => _t(
      '$count results for “$topic”', '$count kết quả cho “$topic”');

  // Navigation (drawer + bottom bar)
  String get navSearch => _t('Search', 'Tìm kiếm');
  String get navTrendsShort => _t('Trends', 'Xu hướng');
  String get navPapersShort => _t('Papers', 'Bài báo');
  String get navDashboardShort => _t('Dashboard', 'Tổng quan');
  String get navCompareShort => _t('Compare', 'So sánh');
  String get menuTrendAnalysis => _t('Trend Analysis', 'Phân tích xu hướng');
  String get menuTopPapers => _t('Top Papers', 'Bài báo hàng đầu');
  String get menuDashboard => _t('Dashboard', 'Tổng quan');
  String get menuTopJournals => _t('Top Journals', 'Tạp chí hàng đầu');
  String get menuTopAuthors => _t('Top Authors', 'Tác giả hàng đầu');
  String get menuCompare => _t('Compare Topics', 'So sánh chủ đề');

  // ─── Compare Topics screen ───────────────────────────────
  String get compareTitle => _t('Compare Topics', 'So sánh Chủ đề');
  String get compareSubtitle =>
      _t('Compare up to 3 research topics', 'So sánh tối đa 3 chủ đề nghiên cứu');
  String get compareInputTitle =>
      _t('Enter 2–3 research topics', 'Nhập 2–3 chủ đề nghiên cứu');
  String compareTopicHint(int index) => _t('Topic $index', 'Chủ đề $index');
  String get compareAddTopic => _t('Add topic', 'Thêm chủ đề');
  String get compareRemoveTopic => _t('Remove topic', 'Bỏ chủ đề');
  String get compareButton => _t('Compare', 'So sánh');
  String get compareValidationMin => _t(
      'Please enter at least 2 non-empty topics',
      'Vui lòng nhập ít nhất 2 chủ đề không để trống');
  String get compareLoading =>
      _t('Comparing topics…', 'Đang so sánh các chủ đề…');
  String get compareEmptyTitle =>
      _t('Compare research topics', 'So sánh các chủ đề nghiên cứu');
  String get compareEmptyMessage => _t(
      'Enter 2 or 3 topics above and tap Compare to see them side by side.',
      'Nhập 2 hoặc 3 chủ đề phía trên rồi nhấn So sánh để xem song song.');

  // Winner summary cards
  String get compareMostPublications =>
      _t('Most publications', 'Nhiều công bố nhất');
  String get compareHighestAvgCitations =>
      _t('Highest avg. citations', 'Trích dẫn TB cao nhất');

  // Comparison table
  String get compareTableTitle => _t('Comparison', 'Bảng so sánh');
  String get compareChartTitle =>
      _t('Publications by topic', 'Số công bố theo chủ đề');
  String get mTotalPublications => _t('Total publications', 'Tổng công bố');
  String get mAvgCitations => _t('Avg. citations', 'Trích dẫn TB');
  String get mMostActiveYear => _t('Most active year', 'Năm sôi động nhất');
  String get mTopJournal => _t('Top journal', 'Tạp chí hàng đầu');
  String get mTopAuthor => _t('Top author', 'Tác giả hàng đầu');
  String get mMostInfluential =>
      _t('Most influential paper', 'Bài báo ảnh hưởng nhất');

  // ─── Topic suggestions (recommendation) ──────────────────
  String get recoTitle => _t('Topic suggestions', 'Gợi ý chọn đề tài');
  String get recoSubtitle => _t(
      'Based on the compared OpenAlex data', 'Dựa trên dữ liệu OpenAlex đã so sánh');

  // Suggestion categories + short labels
  String get recoCatPopular => _t('Most popular', 'Phổ biến nhất');
  String get recoCatImpact => _t('Highest impact', 'Ảnh hưởng cao nhất');
  String get recoCatNarrower =>
      _t('Narrower direction', 'Hướng nghiên cứu hẹp hơn');
  String get recoLabelPopular => _t('Easy to find sources', 'Dễ tìm tài liệu');
  String get recoLabelImpact =>
      _t('High academic impact', 'Ảnh hưởng học thuật cao');
  String get recoLabelNarrower => _t('Narrower niche', 'Hướng hẹp hơn');

  // Reasons (parameterized with the topic name)
  String recoReasonPopular(String topic) => _t(
      '$topic has the most publications, so reference material is easy to find.',
      '$topic có tổng số công bố cao nhất — dễ tìm tài liệu tham khảo.');
  String recoReasonImpact(String topic) => _t(
      '$topic has the highest average citations, signalling strong academic impact.',
      '$topic có trích dẫn trung bình cao nhất — mức độ ảnh hưởng học thuật mạnh.');
  String recoReasonNarrower(String topic) => _t(
      '$topic has fewer publications, a good fit for a narrower, less crowded direction.',
      '$topic có ít công bố hơn — phù hợp cho hướng nghiên cứu hẹp, ít cạnh tranh.');

  // Recommended topic
  String get recoRecommendedTitle => _t('Recommended topic', 'Đề tài được đề xuất');
  String recoRecommendedByImpact(String topic) => _t(
      '$topic is recommended because it has the highest average citations, showing strong academic impact and fitting trend-oriented research.',
      '$topic được đề xuất vì có trích dẫn trung bình cao nhất, cho thấy mức độ ảnh hưởng học thuật mạnh và phù hợp với các đề tài mang tính xu hướng.');
  String recoRecommendedByOverall(String topic) => _t(
      '$topic is recommended for the highest overall score, balancing volume, impact and recency.',
      '$topic được đề xuất vì có điểm tổng hợp cao nhất — cân bằng giữa lượng công bố, mức ảnh hưởng và tính cập nhật.');

  // Score breakdown labels
  String get scorePopularity => _t('Popularity', 'Độ phổ biến');
  String get scoreImpact => _t('Impact', 'Ảnh hưởng');
  String get scoreRecency => _t('Recency', 'Tính cập nhật');
  String get scoreOverall => _t('Overall score', 'Điểm tổng hợp');

  // ─── Trend screen ────────────────────────────────────────
  String get trendTitle => _t('Publication Trend', 'Xu hướng Công bố');
  String trendSubtitleForTopic(String topic) => _t(
      'Research trend for “$topic”', 'Xu hướng nghiên cứu cho “$topic”');
  String get trendSubtitleDefault =>
      _t('Papers published by year', 'Số bài báo công bố theo năm');
  String get loadingTrend =>
      _t('Loading trend data…', 'Đang tải dữ liệu xu hướng…');
  String get loadingJournals =>
      _t('Loading top journals…', 'Đang tải tạp chí hàng đầu…');
  String get loadingAuthors =>
      _t('Loading top authors…', 'Đang tải tác giả hàng đầu…');
  String get noTrendTitle => _t('No trend data', 'Chưa có dữ liệu xu hướng');
  String get noTrendMessage => _t(
      'Search a topic to see how publications evolved over time.',
      'Tìm một chủ đề để xem công bố thay đổi theo thời gian.');
  String get filterByYear => _t('Filter by year', 'Lọc theo năm');
  String get noDataInRange =>
      _t('No data in this range.', 'Không có dữ liệu trong khoảng này.');
  String get statTotalPapers => _t('Total Papers', 'Tổng số bài báo');
  String get statPeakYear => _t('Peak Year', 'Năm cao điểm');
  String get statYearRange => _t('Year Range', 'Khoảng năm');
  String get papersByPublicationYear =>
      _t('Papers by publication year', 'Số bài báo theo năm công bố');
  String get insight => _t('Insight', 'Nhận định');

  String insightPeak(int peakYear, String count) => _t(
      'Publication activity peaked in $peakYear with $count papers.',
      'Hoạt động công bố đạt đỉnh vào năm $peakYear với $count bài báo.');
  String get insightIncreased => _t(
      ' Research activity has generally increased over time.',
      ' Hoạt động nghiên cứu nhìn chung tăng theo thời gian.');
  String get insightDeclined => _t(
      ' Research activity declined after its peak.',
      ' Hoạt động nghiên cứu giảm sau khi đạt đỉnh.');
  String get insightNoRange => _t(
      'No data available for the selected range.',
      'Không có dữ liệu cho khoảng đã chọn.');

  /// Chart tooltip: "{year} · {count} papers"
  String chartPapersTooltip(int year, String count) =>
      _t('$year · $count papers', '$year · $count bài báo');

  // ─── Dashboard screen ────────────────────────────────────
  String get dashboardTitle => _t('Research Dashboard', 'Bảng tổng quan Nghiên cứu');
  String dashboardSubtitleForTopic(String topic) =>
      _t('Key insights for “$topic”', 'Thông tin chính cho “$topic”');
  String get dashboardSubtitleDefault =>
      _t('Key research insights', 'Thông tin nghiên cứu chính');
  String get noDashboardTitle =>
      _t('No dashboard yet', 'Chưa có dữ liệu tổng quan');
  String get noDashboardMessage => _t(
      'Search for a topic to see key research insights.',
      'Tìm một chủ đề để xem thông tin nghiên cứu chính.');
  String get kpiTotalPapers => _t('Total Papers', 'Tổng số bài báo');
  String get kpiAvgCitations => _t('Avg Citations*', 'Trích dẫn TB*');
  String get kpiMostActiveYear => _t('Most Active Year', 'Năm sôi động nhất');
  String get kpiTopAuthor => _t('Top Author', 'Tác giả hàng đầu');
  String get kpiTopJournal => _t('Top Journal', 'Tạp chí hàng đầu');
  String get avgCitationsFootnote => _t(
      '* Average citations calculated from top 200 sampled papers',
      '* Trích dẫn trung bình tính từ 200 bài báo mẫu hàng đầu');
  String get publicationTrend => _t('Publication Trend', 'Xu hướng Công bố');
  String get papersPublishedPerYear =>
      _t('Papers published per year', 'Số bài báo công bố mỗi năm');
  String get noTrendDataAvailable =>
      _t('No trend data available.', 'Không có dữ liệu xu hướng.');
  String get mostInfluentialPaper =>
      _t('Most Influential Paper', 'Bài báo có ảnh hưởng nhất');
  String get noInfluentialData => _t('No influential paper data available.',
      'Không có dữ liệu bài báo ảnh hưởng.');
  String citationsCount(String count) =>
      _t('$count Citations', '$count Trích dẫn');
  String get unknownAuthors => _t('Unknown authors', 'Không rõ tác giả');
  String andMore(int n) => _t(' +$n more', ' +$n khác');
  String get detailsButton => _t('Details', 'Chi tiết');
  String get viewPaperButton => _t('View Paper', 'Xem bài báo');

  // ─── Top Papers screen ───────────────────────────────────
  String get topPapersTitle =>
      _t('Top Influential Papers', 'Bài báo có ảnh hưởng nhất');
  String topPapersSubtitleForTopic(String topic) => _t(
      'Most cited research for “$topic”',
      'Nghiên cứu được trích dẫn nhiều nhất cho “$topic”');
  String get topPapersSubtitleDefault =>
      _t('Highest cited papers', 'Bài báo được trích dẫn nhiều nhất');
  String get rankingPapers => _t('Ranking papers…', 'Đang xếp hạng bài báo…');
  String get noPapersTitle => _t('No papers found', 'Không tìm thấy bài báo');
  String get noPapersMessage => _t(
      'Search a topic to discover its most cited papers.',
      'Tìm một chủ đề để khám phá các bài báo được trích dẫn nhiều nhất.');

  /// Compact "{count} cites" badge.
  String citesBadge(String count) => _t('$count cites', '$count trích dẫn');

  // ─── Top Journals screen ─────────────────────────────────
  String get topJournalsTitle => _t('Top Journals', 'Tạp chí hàng đầu');
  String topJournalsSubtitleForTopic(String topic) => _t(
      'Most active journals for “$topic”',
      'Tạp chí hoạt động nhiều nhất cho “$topic”');
  String get topJournalsSubtitleDefault =>
      _t('Journals ranked by publications', 'Tạp chí xếp hạng theo số công bố');
  String get noJournalsTitle => _t('No journals yet', 'Chưa có tạp chí');
  String get noJournalsMessage => _t(
      'Search a topic first to rank journals by publication count.',
      'Hãy tìm một chủ đề trước để xếp hạng tạp chí theo số công bố.');

  // ─── Top Authors screen ──────────────────────────────────
  String get topAuthorsTitle => _t('Top Authors', 'Tác giả hàng đầu');
  String topAuthorsSubtitleForTopic(String topic) => _t(
      'Most prolific authors for “$topic”',
      'Tác giả có nhiều công bố nhất cho “$topic”');
  String get topAuthorsSubtitleDefault =>
      _t('Authors ranked by publications', 'Tác giả xếp hạng theo số công bố');
  String get noAuthorsTitle => _t('No authors yet', 'Chưa có tác giả');
  String get noAuthorsMessage => _t(
      'Search a topic first to rank authors by publication count.',
      'Hãy tìm một chủ đề trước để xếp hạng tác giả theo số công bố.');

  // ─── Publication detail screen ───────────────────────────
  String get detailAppBarTitle => _t('Publication', 'Công bố');
  String get openPaperTooltip => _t('Open paper', 'Mở bài báo');
  String get untitledWork => _t('Untitled work', 'Tài liệu chưa có tiêu đề');
  String citationsChip(String count) =>
      _t('$count citations', '$count trích dẫn');
  String get readFullPaper => _t('Read full paper', 'Đọc toàn văn');

  String get sectionOverview => _t('Overview', 'Tổng quan');
  String get fieldSource => _t('Source', 'Nguồn');
  String get fieldAuthors => _t('Authors', 'Tác giả');
  String get fieldInstitutions => _t('Institutions', 'Cơ quan');
  String get fieldLanguage => _t('Language', 'Ngôn ngữ');

  String get sectionMetrics =>
      _t('Citations & metrics', 'Trích dẫn & chỉ số');
  String get fieldFwci => 'FWCI'; // metric acronym — kept as-is
  String get fieldReferences => _t('References', 'Tài liệu tham khảo');
  String get fieldCitedBy => _t('Cited by', 'Được trích bởi');
  String get fieldRelatedWorks => _t('Related works', 'Công trình liên quan');
  String get fieldDoi => 'DOI'; // identifier — kept as-is

  String get sectionTaxonomy => _t('Topic taxonomy', 'Phân loại chủ đề');
  String get fieldTopic => _t('Topic', 'Chủ đề');
  String get fieldSubfield => _t('Subfield', 'Lĩnh vực con');
  String get fieldField => _t('Field', 'Lĩnh vực');
  String get fieldDomain => _t('Domain', 'Miền');
  String get fieldSdg => 'SDG'; // acronym — kept as-is

  String get sectionAccessFunding =>
      _t('Access & funding', 'Truy cập & tài trợ');
  String get fieldOpenAccess => _t('Open access', 'Truy cập mở');
  String get fieldFunders => _t('Funders', 'Nhà tài trợ');
  String get fieldAwards => _t('Awards', 'Giải thưởng');

  String get sectionAbstract => _t('Abstract', 'Tóm tắt');
  String get showLess => _t('Show less', 'Thu gọn');
  String plusMore(int n) => _t('+$n more', '+$n khác');

  // ─── Bottom navigation tabs ──────────────────────────────
  String get tabHome => _t('Home', 'Trang chủ');
  String get tabJournals => _t('Journals', 'Tạp chí');
  String get tabKeywords => _t('Keywords', 'Từ khóa');
  String get tabProfile => _t('Profile', 'Hồ sơ');

  // ─── Drawer / shared actions ─────────────────────────────
  String get signOut => _t('Sign out', 'Đăng xuất');
  String get viewAll => _t('View All', 'Xem tất cả');
  String get open => _t('Open', 'Mở');
  String get copy => _t('Copy', 'Sao chép');
  String get refresh => _t('Refresh', 'Làm mới');

  // ─── No-results empty state (0 papers) ───────────────────
  String get noResultsTitle =>
      _t('No publications found', 'Không tìm thấy công bố');
  String noResultsMessage(String keyword) => _t(
      "No publications found for '$keyword'. Try a different keyword.",
      "Không tìm thấy công bố nào cho '$keyword'. Hãy thử từ khóa khác.");

  // ─── Shared research-topic search (Home / Journals / Keywords) ──
  /// Unified placeholder so the three synced search bars don't read like
  /// per-screen filters.
  String get searchTopicHint =>
      _t('Search research topic...', 'Tìm chủ đề nghiên cứu...');
  String currentTopicLabel(String topic) =>
      _t('Topic: $topic', 'Chủ đề: $topic');
  String get clearTopicTooltip => _t('Clear topic', 'Xóa chủ đề');

  // ─── Search hints per screen ─────────────────────────────
  String get dashboardSearchHint =>
      _t('Search topic for dashboard insights', 'Tìm chủ đề để xem tổng quan');
  String get papersRetrievedLabel =>
      _t('Papers Retrieved:', 'Số bài báo lấy về:');
  String get trendSearchHint => _t(
      'Search topic for trend analysis', 'Tìm chủ đề để phân tích xu hướng');
  String get topJournalsSearchHint => _t(
      'Search topic for top journals', 'Tìm chủ đề để xem tạp chí hàng đầu');
  String get topAuthorsSearchHint => _t(
      'Search topic for top authors', 'Tìm chủ đề để xem tác giả hàng đầu');

  // ─── Journals tab ────────────────────────────────────────
  String get journalsTabTitle => _t('Journals', 'Tạp chí');
  String get journalsTabSubtitle =>
      _t('Journal-level analysis', 'Phân tích theo tạp chí');
  String get journalsSearchHint => _t(
      'Search a topic to analyze journals', 'Nhập chủ đề để phân tích tạp chí');
  String get journalsLoading => _t('Loading journals…', 'Đang tải tạp chí…');
  String get journalsEmptyTitle =>
      _t('No journal data', 'Chưa có dữ liệu tạp chí');
  String get journalsEmptyMessage => _t(
      'Search a topic to see the top journals.',
      'Tìm một chủ đề để xem các tạp chí hàng đầu.');
  String get journalsContribution =>
      _t('Contribution by journal', 'Đóng góp theo tạp chí');
  String get journalsRanking => _t('Journal ranking', 'Xếp hạng tạp chí');

  // Shared stat labels (journals + journal detail)
  String get statJournals => _t('Journals', 'Tạp chí');
  String get statPublications => _t('Publications', 'Công bố');
  String get statCitations => _t('Citations', 'Trích dẫn');
  String get statTotalCitations => _t('Total citations', 'Tổng trích dẫn');
  String get statAvgCitationsPerPub =>
      _t('Avg. citations / publication', 'Trung bình trích dẫn / công bố');
  String journalRankSubtitle(int count, String avg) => _t(
      '$count publications · avg $avg citations',
      '$count công bố · TB $avg trích dẫn');

  // ─── Journal detail ──────────────────────────────────────
  String get journalDetailSubtitle => _t('Journal details', 'Chi tiết tạp chí');
  String get relatedPublications =>
      _t('Related publications', 'Công bố liên quan');

  // ─── Keywords tab ────────────────────────────────────────
  String get keywordsTabTitle => _t('Keywords', 'Từ khóa');
  String get keywordsTabSubtitle => _t('Keyword analysis', 'Phân tích từ khóa');
  String get keywordsSearchHint => _t(
      'Search a topic to analyze keywords', 'Nhập chủ đề để phân tích từ khóa');
  String get keywordsLoading => _t('Loading keywords…', 'Đang tải từ khóa…');
  String get keywordsEmptyTitle =>
      _t('No keyword data', 'Chưa có dữ liệu từ khóa');
  String get keywordsEmptyMessage => _t(
      'Search a topic to see popular keywords.',
      'Tìm một chủ đề để xem các từ khóa phổ biến.');
  String get keywordsTrending => _t('Trending keywords', 'Từ khóa nổi bật');
  String get keywordsFrequency => _t('Keyword frequency', 'Tần suất từ khóa');

  // ─── Keyword detail ──────────────────────────────────────
  String get keywordDetailSubtitle =>
      _t('Keyword analysis', 'Phân tích từ khóa');
  String get analyzing => _t('Analyzing…', 'Đang phân tích…');
  String get keywordTrendTitle => _t('Publication trend', 'Xu hướng công bố');
  String get noTrendShort => _t('No trend data', 'Không có dữ liệu xu hướng');
  String get topContributingAuthors =>
      _t('Top contributing authors', 'Tác giả đóng góp hàng đầu');
  String get relatedJournals => _t('Related journals', 'Tạp chí liên quan');

  // ─── Profile screen ──────────────────────────────────────
  String get profileTitle => _t('Profile', 'Hồ sơ');
  String get profileSubtitle =>
      _t('Account & Firebase services', 'Tài khoản & dịch vụ Firebase');
  String get profileDemoName => _t('Demo mode', 'Chế độ demo');
  String get profileGuestName => _t('Guest', 'Khách');
  String get profileNotSignedIn => _t('Not signed in', 'Chưa đăng nhập');
  String get notificationCenterTitle =>
      _t('Notification Center', 'Trung tâm thông báo');
  String get noNotifications =>
      _t('No FCM notifications yet.', 'Chưa có thông báo nào từ FCM.');
  String get exportPdfTitle => _t('Export PDF report', 'Xuất báo cáo PDF');
  String get exportPdfHint => _t(
      'Search a topic on the Home tab first, then come back to export a report.',
      'Hãy tìm một chủ đề ở tab Home trước, rồi quay lại để xuất báo cáo.');
  String exportTopicLabel(String topic) => _t('Topic: $topic', 'Chủ đề: $topic');
  String get exportInProgress =>
      _t('Creating & uploading…', 'Đang tạo & tải lên…');
  String get exportButton =>
      _t('Export PDF & upload to Storage', 'Xuất PDF & tải lên Storage');
  String get uploadedToStorage =>
      _t('Uploaded to Firebase Storage', 'Đã tải lên Firebase Storage');
  String get urlCopied => _t('URL copied', 'Đã sao chép URL');
  // Firebase product names — intentionally kept identical in both languages.
  String get remoteConfigTitle => 'Remote Config';
  String get crashlyticsDemoTitle => 'Crashlytics Demo';
  String get handledExceptionButton =>
      _t('Handled exception', 'Ngoại lệ đã xử lý');
  String get testCrashButton => _t('Test crash', 'Thử gây crash');
  String get handledExceptionSent =>
      _t('Handled exception sent', 'Đã gửi ngoại lệ đã xử lý');
  String get crashlyticsHint => _t(
      'Test crash will close the app; the report appears in Firebase Console after a few minutes.',
      'Test crash sẽ đóng app; báo cáo xuất hiện trong Firebase Console sau ít phút.');
  String get linkOpenFailed =>
      _t('Could not open the link', 'Không mở được liên kết');
  String linkOpenFailedDetail(String error) =>
      _t('Could not open the link: $error', 'Không mở được liên kết: $error');

  // ─── Login screen ────────────────────────────────────────
  String get loginSubtitle => _t(
      'Analyze scientific research trends\nwith OpenAlex data',
      'Phân tích xu hướng nghiên cứu khoa học\nvới dữ liệu OpenAlex');
  String get signInWithGoogle => _t('Sign in with Google', 'Đăng nhập với Google');
  String get tryDemoMode => _t('Try demo mode →', 'Xem thử ở chế độ demo →');
  String get firebaseNotConfigured => _t(
      'Firebase is not configured. See FIREBASE_SETUP.md to enable sign-in.',
      'Firebase chưa được cấu hình. Xem FIREBASE_SETUP.md để bật đăng nhập.');
  String get poweredBy =>
      _t('Powered by Firebase & OpenAlex', 'Được hỗ trợ bởi Firebase & OpenAlex');
}
