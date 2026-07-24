import 'package:flutter/material.dart';

import '../firebase/analytics_service.dart';
import '../l10n/locale_provider.dart';
import '../models/journal_stat.dart';
import '../theme/app_theme.dart';
import '../utils/widget_keys.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// Journal Details (lab §4.5): name, total publications, total citations,
/// average citations per publication, and related publications.
class JournalDetailScreen extends StatefulWidget {
  final JournalStat journal;
  const JournalDetailScreen({super.key, required this.journal});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logViewJournal(widget.journal.name);
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.journal;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          BrandedHeader(
            key: const ValueKey(WidgetKeys.journalDetailTitle),
            title: j.name,
            subtitle: j.issn.isNotEmpty ? 'ISSN: ${j.issn}' : '',
            icon: Icons.menu_book_rounded,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _stat(context.s.statPublications,
                            '${j.publicationCount}',
                            Icons.description_rounded, AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _stat(context.s.statTotalCitations,
                            '${j.totalCitations}',
                            Icons.format_quote_rounded, AppColors.amber)),
                  ],
                ),
                const SizedBox(height: 12),
                _wideStat(context.s.statAvgCitationsPerPub,
                    j.averageCitations.toStringAsFixed(2), Icons.star_rounded,
                    AppColors.emerald),
                const SizedBox(height: 24),
                Text(context.s.relatedPublications,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                ...j.publications.asMap().entries.map((entry) {
                  final p = entry.value;
                  return Padding(
                      key: entry.key == 0
                          ? const ValueKey(WidgetKeys.publicationListFirst)
                          : null,
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
                    );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
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
                  color: AppColors.ink)),
          Text(label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _wideStat(String label, String value, IconData icon, Color color) {
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
                Text(label,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.muted)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
