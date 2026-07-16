import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/locale_provider.dart';
import '../providers/top_journal_provider.dart';
import '../providers/recent_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/topic_search_bar.dart';

class TopJournalScreen extends StatefulWidget {
  const TopJournalScreen({super.key});

  @override
  State<TopJournalScreen> createState() => _TopJournalScreenState();
}

class _TopJournalScreenState extends State<TopJournalScreen> {
  String _currentSearchText = "";

  void _onSearch(String text) {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.enterTopicWarning)),
      );
      return;
    }
    setState(() {
      _currentSearchText = text;
    });
    context.read<RecentProvider>().addSearch(text);
    Provider.of<TopJournalProvider>(context, listen: false).search(text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TopJournalProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          BrandedHeader(
            title: context.s.topJournalsTitle,
            subtitle: provider.currentTopic.isNotEmpty
                ? context.s.topJournalsSubtitleForTopic(provider.currentTopic)
                : context.s.topJournalsSubtitleDefault,
            icon: Icons.menu_book_rounded,
            child: TopicSearchBar(
              hintText: context.s.topJournalsSearchHint,
              initialValue: _currentSearchText,
              onSearch: _onSearch,
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(TopJournalProvider provider) {
    if (provider.isLoading) {
      return StateView.loading(message: context.s.loadingJournals);
    }

    if (provider.errorMessage.isNotEmpty) {
      return StateView.error(
        context.s.somethingWentWrong,
        onRetry: () => provider.search(provider.currentTopic),
      );
    }

    final sorted = provider.journals;
    final maxCount = provider.maxCount;

    if (sorted.isEmpty && provider.currentTopic.isNotEmpty) {
      return StateView.empty(
        icon: Icons.menu_book_rounded,
        title: context.s.noJournalsTitle,
        message: context.s.noJournalsMessage,
      );
    } else if (sorted.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = sorted[index];
        return _journalCard(
            context, index + 1, entry.key, entry.value, maxCount);
      },
    );
  }

  Widget _journalCard(
      BuildContext context, int rank, String name, int count, int maxCount) {
    final ratio = (count / maxCount).clamp(0.05, 1.0);
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          RankBadge(rank: rank),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.3)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: AppColors.primarySoft,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$count",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              Text(context.s.papersUnit,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
