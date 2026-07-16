import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase/analytics_service.dart';
import '../l10n/locale_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/recent_provider.dart';
import '../providers/top_journal_provider.dart';
import '../providers/top_author_provider.dart';
import '../models/dashboard_summary.dart';
import '../theme/app_theme.dart';
import '../viewmodels/topic_provider.dart';
import '../viewmodels/topic_reset.dart';
import '../widgets/common.dart';
import '../widgets/current_topic_chip.dart';
import '../widgets/topic_search_bar.dart';
import 'detail_screen.dart';
import 'top_journal_screen.dart';
import 'top_author_screen.dart';
import 'author_detail_screen.dart';
class DashboardScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const DashboardScreen({super.key, this.scaffoldKey});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentSearchText = "";

  void _onSearch(String topic) {
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.enterTopicWarning)),
      );
      return;
    }
    setState(() {
      _currentSearchText = topic;
    });
    context.read<RecentProvider>().addSearch(topic);
    // Share the topic with the Journals/Keywords tabs and track analytics.
    context.read<TopicProvider>().setTopic(topic);
    AnalyticsService.instance.logSearchTopic(topic);

    Provider.of<DashboardProvider>(context, listen: false).search(topic);
    Provider.of<TopJournalProvider>(context, listen: false).search(topic);
    Provider.of<TopAuthorProvider>(context, listen: false).search(topic);
  }

  void _onChipTapped(String topic) {
    _onSearch(topic);
  }

  void _clearTopic() {
    clearGlobalTopic(context);
    setState(() => _currentSearchText = "");
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);

    return Column(
      children: [
        _buildHeader(provider),
        Expanded(child: _buildBody(context, provider)),
      ],
    );
  }

  // ─── Header with search ─────────────────────────────────

  Widget _buildHeader(DashboardProvider provider) {
    // The shared research topic drives the search bar text on all three tabs.
    final topic = context.watch<TopicProvider>().topic;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        widget.scaffoldKey?.currentState?.openDrawer();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(Icons.menu_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.s.dashboardTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.s.searchHeaderSubtitle,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TopicSearchBar(
                hintText: context.s.searchTopicHint,
                initialValue: topic,
                onSearch: _onSearch,
              ),
              if (topic.isNotEmpty) ...[
                const SizedBox(height: 12),
                CurrentTopicChip(topic: topic, onClear: _clearTopic),
              ],
              _buildPapersRetrieved(provider),
              const SizedBox(height: 16),
              _buildTopicChips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicChips() {
    final topics = [
      "Artificial Intelligence",
      "Data Science",
      "Cybersecurity",
      "Blockchain",
      "IoT",
    ];
    final chipHeight =
        MediaQuery.textScalerOf(context).scale(34).clamp(34.0, 52.0);
    return SizedBox(
      height: chipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return Center(
            child: Material(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _onChipTapped(topics[i]),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Text(
                    topics[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Shows the real number of papers retrieved, but only after the user has
  // searched. Before any search it stays hidden so we never show a stale "50".
  Widget _buildPapersRetrieved(DashboardProvider provider) {
    if (!provider.hasSearched) return const SizedBox.shrink();

    final value = provider.isLoading ? "…" : "${provider.papersRetrieved}";
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            context.s.papersRetrievedLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ─── Body ───────────────────────────────────────────────

  Widget _buildBody(BuildContext context, DashboardProvider provider) {
    if (provider.isLoading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSkeletonKPIGrid(),
            const SizedBox(height: 16),
            _buildSkeletonCard(220),
            const SizedBox(height: 16),
            _buildSkeletonCard(180),
          ],
        ),
      );
    }

    if (provider.errorMessage.isNotEmpty) {
      return StateView.error(
        provider.errorMessage,
        title: context.s.somethingWentWrong,
        retryLabel: context.s.tryAgain,
        onRetry: () => provider.search(provider.currentTopic),
      );
    }

    final summary = provider.dashboardSummary;
    if (summary == null) {
      return StateView.empty(
        icon: Icons.insights_rounded,
        title: context.s.noDashboardTitle,
        message: context.s.noDashboardMessage,
      );
    }

    // A completed search that returned no publications: show a friendly
    // empty state instead of a grid full of 0 / N/A values.
    if (summary.totalPublications == 0 && summary.papersRetrieved == 0) {
      return StateView.empty(
        icon: Icons.search_off_rounded,
        title: context.s.noResultsTitle,
        message: context.s.noResultsMessage(provider.currentTopic),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPIGrid(context, summary),
          const SizedBox(height: 16),
          _buildMiniTrendChart(context, summary),
          const SizedBox(height: 16),
          _buildMostInfluentialCard(context, summary),
          const SizedBox(height: 24),
          _buildTopJournalsPreview(context),
          const SizedBox(height: 24),
          _buildTopAuthorsPreview(context),
        ],
      ),
    );
  }

  Widget _buildTopJournalsPreview(BuildContext context) {
    final provider = Provider.of<TopJournalProvider>(context);
    
    if (provider.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context.s.topJournalsTitle, null),
          const SizedBox(height: 12),
          _buildSkeletonCard(80),
        ],
      );
    }
    
    if (provider.journals.isEmpty) return const SizedBox.shrink();

    final items = provider.journals.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.s.topJournalsTitle, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TopJournalScreen()),
          );
        }),
        const SizedBox(height: 12),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final journal = entry.value; // MapEntry<String, int>
              final name = journal.key.isEmpty ? "Unknown" : journal.key;
              final count = journal.value;
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.indigo.withValues(alpha: 0.1),
                      child: const Icon(Icons.menu_book_rounded, color: AppColors.indigo, size: 20),
                    ),
                    title: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    trailing: Text(
                      "$count",
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TopJournalScreen()),
                      );
                    },
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAuthorsPreview(BuildContext context) {
    final provider = Provider.of<TopAuthorProvider>(context);
    
    if (provider.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context.s.topAuthorsTitle, null),
          const SizedBox(height: 12),
          _buildSkeletonCard(80),
        ],
      );
    }

    if (provider.authors.isEmpty) return const SizedBox.shrink();

    final items = provider.authors.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.s.topAuthorsTitle, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TopAuthorScreen()),
          );
        }),
        const SizedBox(height: 12),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final author = entry.value;
              
              String initials = "";
              final parts = author.name
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((p) => p.isNotEmpty)
                  .toList();
              if (parts.isNotEmpty) {
                initials = parts.first[0].toUpperCase();
                if (parts.length > 1) {
                  initials += parts.last[0].toUpperCase();
                }
              }

              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.violet.withValues(alpha: 0.1),
                      child: Text(
                        initials,
                        style: const TextStyle(color: AppColors.violet, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    title: Text(
                      author.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    trailing: Text(
                      "${author.worksCount}",
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthorDetailScreen(
                            authorId: author.id,
                            authorName: author.name,
                            topic: _currentSearchText,
                          ),
                        ),
                      );
                    },
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, VoidCallback? onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.s.viewAll,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  // ─── KPI Grid ────────────────────────────────────────────

  Widget _buildKPIGrid(BuildContext context, ResearchDashboardSummary summary) {
    final totalText = _formatNumber(summary.totalPublications);
    final avgText = summary.averageCitationCount.toStringAsFixed(1);
    final yearText = summary.mostActiveYear != null
        ? "${summary.mostActiveYear}"
        : context.s.notAvailable;
    final journalText = summary.topJournal ?? context.s.notAvailable;
    final authorText = summary.topAuthor ?? context.s.notAvailable;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _kpiCard(context.s.kpiTotalPapers, totalText,
                    Icons.description_rounded, AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: _kpiCard(context.s.kpiAvgCitations, avgText,
                    Icons.star_rounded, AppColors.amber)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _kpiCard(context.s.kpiMostActiveYear, yearText,
                    Icons.calendar_today_rounded, AppColors.emerald)),
            const SizedBox(width: 12),
            Expanded(
                child: _kpiCard(context.s.kpiTopAuthor, authorText,
                    Icons.person_rounded, AppColors.violet)),
          ],
        ),
        const SizedBox(height: 12),
        _wideKpiCard(context.s.kpiTopJournal, journalText,
            Icons.menu_book_rounded, AppColors.indigo),
        const SizedBox(height: 8),
        Text(
          context.s.avgCitationsFootnote,
          style: const TextStyle(
              fontSize: 11, color: AppColors.faint, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _wideKpiCard(String title, String value, IconData icon, Color color) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mini Trend Chart ────────────────────────────────────

  Widget _buildMiniTrendChart(
      BuildContext context, ResearchDashboardSummary summary) {
    final trendData = summary.publicationTrend
        .where((t) => t.year >= 1900 && t.year <= DateTime.now().year)
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));

    if (trendData.isEmpty) {
      return SectionCard(
        child: Center(
            child: Text(context.s.noTrendDataAvailable,
                style: const TextStyle(color: AppColors.muted))),
      );
    }

    final spots =
        trendData.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
    final firstYear = trendData.first.year;
    final lastYear = trendData.last.year;
    final maxCount = trendData.map((t) => t.count).reduce(max);
    final interval = max(1.0, ((lastYear - firstYear) / 4).floorToDouble());
    // Guard degenerate ranges (a single year, or all-zero counts): a zero-width
    // axis makes fl_chart divide by zero and throw a null-check internally.
    final double minX = firstYear.toDouble();
    final double maxX =
        firstYear == lastYear ? firstYear + 1.0 : lastYear.toDouble();
    final double maxY = (maxCount <= 0 ? 1 : maxCount) * 1.2;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
              title: context.s.publicationTrend,
              icon: Icons.show_chart_rounded),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(context.s.papersPublishedPerYear,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: interval,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(value.toInt().toString(),
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11)),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: max(1, (maxCount / 4).floorToDouble()),
                      getTitlesWidget: (value, meta) {
                        if (value == value.toInt().toDouble()) {
                          return Text(_formatNumber(value.toInt()),
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 11));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBright, AppColors.primary],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.20),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.ink,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        try {
                          return LineTooltipItem(
                            context.s.chartPapersTooltip(spot.x.toInt(),
                                _formatNumber(spot.y.toInt())),
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          );
                        } catch (_) {
                          return const LineTooltipItem(
                            '',
                            TextStyle(color: Colors.white),
                          );
                        }
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Most Influential Paper Card ─────────────────────────

  Widget _buildMostInfluentialCard(
      BuildContext context, ResearchDashboardSummary summary) {
    final paper = summary.mostInfluentialPaper;
    if (paper == null) {
      return SectionCard(
        child: Center(
            child: Text(context.s.noInfluentialData,
                style: const TextStyle(color: AppColors.muted))),
      );
    }

    final authorsText = paper.authors.isNotEmpty
        ? paper.authors.take(3).join(", ") +
            (paper.authors.length > 3
                ? context.s.andMore(paper.authors.length - 3)
                : "")
        : context.s.unknownAuthors;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
              title: context.s.mostInfluentialPaper,
              icon: Icons.emoji_events_rounded,
              color: AppColors.amber),
          const SizedBox(height: 16),
          Text(paper.title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              MetaChip(
                  icon: Icons.format_quote_rounded,
                  label: context.s
                      .citationsCount(_formatNumber(paper.citationCount)),
                  color: AppColors.primary),
              const SizedBox(width: 10),
              MetaChip(
                  icon: Icons.calendar_today_rounded,
                  label: "${paper.year}",
                  color: AppColors.emerald),
            ],
          ),
          const SizedBox(height: 12),
          Text(authorsText,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.muted, height: 1.4)),
          if (paper.journal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.menu_book_rounded,
                    size: 14, color: AppColors.faint),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(paper.journal,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.faint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => DetailScreen(publication: paper))),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: Text(context.s.detailsButton),
                ),
              ),
              if (paper.doi.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(paper.doi);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(context.s.viewPaperButton),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Skeleton Loaders ────────────────────────────────────

  Widget _buildSkeletonKPIGrid() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _buildSkeletonCard(108)),
          const SizedBox(width: 12),
          Expanded(child: _buildSkeletonCard(108)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildSkeletonCard(108)),
          const SizedBox(width: 12),
          Expanded(child: _buildSkeletonCard(108)),
        ]),
      ],
    );
  }

  Widget _buildSkeletonCard(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────

  String _formatNumber(int number) {
    if (number >= 1000000) return "${(number / 1000000).toStringAsFixed(1)}M";
    if (number >= 1000) return "${(number / 1000).toStringAsFixed(1)}K";
    return "$number";
  }
}
