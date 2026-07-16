import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/locale_provider.dart';
import '../models/journal_stat.dart';
import '../theme/app_theme.dart';
import '../utils/widget_keys.dart';
import '../viewmodels/journals_view_model.dart';
import '../viewmodels/topic_provider.dart';
import '../viewmodels/topic_reset.dart';
import '../widgets/collapsible_branded_header.dart';
import '../widgets/common.dart';
import '../widgets/current_topic_chip.dart';
import '../widgets/topic_search_bar.dart';
import 'journal_detail_screen.dart';

/// Journals tab (lab §4.4): journal-level analysis for the selected topic.
class JournalsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const JournalsScreen({super.key, this.onMenuTap});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen>
    with HeaderCollapseMixin {
  String? _lastLoaded;

  void _search(String topic) {
    context.read<TopicProvider>().setTopic(topic);
    context.read<JournalsViewModel>().search(topic);
    _lastLoaded = topic;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JournalsViewModel>();
    final topic = context.watch<TopicProvider>().topic;

    // Keep the tab in sync with the shared topic: auto-load a newly set topic,
    // and forget the last-loaded topic once it has been cleared.
    if (topic.isEmpty) {
      _lastLoaded = null;
    } else if (topic != _lastLoaded && !vm.isLoading) {
      _lastLoaded = topic;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<JournalsViewModel>().search(topic);
      });
    }

    return Column(
      children: [
        CollapsibleBrandedHeader(
          title: context.s.journalsTabTitle,
          subtitle: context.s.journalsTabSubtitle,
          onMenuTap: widget.onMenuTap,
          collapsed: headerCollapsed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TopicSearchBar(
                hintText: context.s.searchTopicHint,
                initialValue: topic,
                onSearch: _search,
                fieldKey: const ValueKey(WidgetKeys.searchFieldJournals),
                submitKey: const ValueKey(WidgetKeys.searchSubmitJournals),
              ),
              if (topic.isNotEmpty) ...[
                const SizedBox(height: 12),
                CurrentTopicChip(
                    topic: topic, onClear: () => clearGlobalTopic(context)),
              ],
            ],
          ),
        ),
        Expanded(
          child: NotificationListener<UserScrollNotification>(
            onNotification: onBodyScroll,
            child: _body(vm),
          ),
        ),
      ],
    );
  }

  Widget _body(JournalsViewModel vm) {
    if (vm.isLoading) {
      return StateView.loading(message: context.s.journalsLoading);
    }
    if (vm.errorMessage.isNotEmpty) {
      return StateView.error(vm.errorMessage,
          title: context.s.somethingWentWrong,
          retryLabel: context.s.tryAgain,
          onRetry: () => vm.search(vm.currentTopic));
    }
    if (vm.journals.isEmpty) {
      // After a search that returned nothing, show the "no results" state.
      if (vm.currentTopic.isNotEmpty) {
        return StateView.empty(
          icon: Icons.search_off_rounded,
          title: context.s.noResultsTitle,
          message: context.s.noResultsMessage(vm.currentTopic),
        );
      }
      return StateView.empty(
        icon: Icons.menu_book_rounded,
        title: context.s.journalsEmptyTitle,
        message: context.s.journalsEmptyMessage,
      );
    }

    final journals = vm.journals;
    final totalPubs =
        journals.fold<int>(0, (s, j) => s + j.publicationCount);
    final totalCites =
        journals.fold<int>(0, (s, j) => s + j.totalCitations);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        // Summary
        Row(
          children: [
            Expanded(
                child: _stat(context.s.statJournals, '${journals.length}',
                    Icons.menu_book_rounded, AppColors.indigo)),
            const SizedBox(width: 12),
            Expanded(
                child: _stat(context.s.statPublications, '$totalPubs',
                    Icons.description_rounded, AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: _stat(context.s.statCitations, '$totalCites',
                    Icons.format_quote_rounded, AppColors.amber)),
          ],
        ),
        const SizedBox(height: 20),
        // Contribution chart (top 5 by publication count)
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                  title: context.s.journalsContribution,
                  icon: Icons.bar_chart_rounded),
              const SizedBox(height: 16),
              ...journals.take(5).map((j) => _bar(j, vm.maxCount)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(context.s.journalsRanking,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 12),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: journals.asMap().entries.map((entry) {
              final i = entry.key;
              final j = entry.value;
              return Column(
                key: i == 0
                    ? const ValueKey(WidgetKeys.journalListFirst)
                    : null,
                children: [
                  ListTile(
                    leading: RankBadge(rank: i + 1),
                    title: Text(j.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(context.s.journalRankSubtitle(
                        j.publicationCount,
                        j.averageCitations.toStringAsFixed(1))),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.faint),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => JournalDetailScreen(journal: j)),
                    ),
                  ),
                  if (i < journals.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _bar(JournalStat j, int maxCount) {
    final fraction = (j.publicationCount / maxCount).clamp(0.05, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(j.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text('${j.publicationCount}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.primarySoft,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
