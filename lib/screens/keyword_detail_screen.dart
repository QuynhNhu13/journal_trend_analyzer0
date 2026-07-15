import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../firebase/analytics_service.dart';
import '../models/author.dart';
import '../theme/app_theme.dart';
import '../viewmodels/keyword_detail_view_model.dart';
import '../widgets/common.dart';
import 'author_detail_screen.dart';
import 'detail_screen.dart';

/// Keyword Details (lab §4.7). Owns a local ViewModel and drives it on init.
class KeywordDetailScreen extends StatefulWidget {
  final String keyword;
  const KeywordDetailScreen({super.key, required this.keyword});

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  final KeywordDetailViewModel _vm = KeywordDetailViewModel();

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logViewKeyword(widget.keyword);
    _vm.load(widget.keyword);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          BrandedHeader(
            title: widget.keyword,
            subtitle: 'Phân tích từ khóa',
            icon: Icons.tag_rounded,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) {
                if (_vm.isLoading) {
                  return StateView.loading(message: 'Đang phân tích…');
                }
                if (_vm.errorMessage.isNotEmpty) {
                  return StateView.error(_vm.errorMessage,
                      onRetry: () => _vm.load(widget.keyword));
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  children: [
                    _trendCard(),
                    const SizedBox(height: 20),
                    _authorsCard(),
                    const SizedBox(height: 20),
                    _journalsCard(),
                    const SizedBox(height: 20),
                    _publicationsSection(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Trend chart ──
  Widget _trendCard() {
    final data = _vm.trend;
    if (data.isEmpty) {
      return SectionCard(
        child: Center(
            child: Text('Không có dữ liệu xu hướng',
                style: const TextStyle(color: AppColors.muted))),
      );
    }
    final spots =
        data.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
    final maxCount = data.map((t) => t.count).reduce(max);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
              title: 'Xu hướng công bố', icon: Icons.show_chart_rounded),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: max(1, (data.length / 4)).floorToDouble(),
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 10)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: max(1, (maxCount / 4)).floorToDouble(),
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                        colors: [AppColors.violet, AppColors.primary]),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.violet.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top contributing authors (ranked desc) ──
  Widget _authorsCard() {
    final authors = _vm.authors;
    if (authors.isEmpty) return const SizedBox.shrink();
    final maxWorks = authors.first.worksCount == 0 ? 1 : authors.first.worksCount;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
              title: 'Tác giả đóng góp hàng đầu',
              icon: Icons.people_alt_rounded),
          const SizedBox(height: 8),
          ...authors.asMap().entries.map((e) {
            final rank = e.key + 1;
            final a = e.value;
            final fraction = (a.worksCount / maxWorks).clamp(0.05, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: () => _openAuthor(a),
                child: Row(
                  children: [
                    SizedBox(
                        width: 26,
                        child: Text('$rank',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 7,
                              backgroundColor: AppColors.primarySoft,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.violet),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${a.worksCount}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openAuthor(TopAuthor a) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthorDetailScreen(
          authorId: a.id,
          authorName: a.name,
          topic: widget.keyword,
        ),
      ),
    );
  }

  // ── Related journals ──
  Widget _journalsCard() {
    if (_vm.journals.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
              title: 'Tạp chí liên quan', icon: Icons.menu_book_rounded),
          const SizedBox(height: 12),
          ..._vm.journals.map((j) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 7, color: AppColors.indigo),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(j.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13))),
                    Text('${j.value}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Related publications ──
  Widget _publicationsSection() {
    if (_vm.publications.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Công bố liên quan',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 12),
        ..._vm.publications.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailScreen(publication: p)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.35)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          MetaChip(
                              icon: Icons.format_quote_rounded,
                              label: '${p.citationCount}',
                              color: AppColors.primary),
                          const SizedBox(width: 8),
                          MetaChip(
                              icon: Icons.calendar_today_rounded,
                              label: '${p.year}',
                              color: AppColors.emerald),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
