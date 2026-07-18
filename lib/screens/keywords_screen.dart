import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/locale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/widget_keys.dart';
import '../viewmodels/keywords_view_model.dart';
import '../viewmodels/topic_provider.dart';
import '../viewmodels/topic_reset.dart';
import '../widgets/collapsible_branded_header.dart';
import '../widgets/common.dart';
import '../widgets/current_topic_chip.dart';
import '../widgets/topic_search_bar.dart';
import 'keyword_detail_screen.dart';

/// Keywords tab (lab §4.6): keyword-based research analysis for the topic.
class KeywordsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const KeywordsScreen({super.key, this.onMenuTap});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen>
    with HeaderCollapseMixin {
  String? _lastLoaded;

  void _search(String topic) {
    context.read<TopicProvider>().setTopic(topic);
    context.read<KeywordsViewModel>().search(topic);
    _lastLoaded = topic;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KeywordsViewModel>();
    final topic = context.watch<TopicProvider>().topic;

    // Keep the tab in sync with the shared topic: auto-load a newly set topic,
    // and forget the last-loaded topic once it has been cleared.
    if (topic.isEmpty) {
      _lastLoaded = null;
    } else if (topic != _lastLoaded && !vm.isLoading) {
      _lastLoaded = topic;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<KeywordsViewModel>().search(topic);
      });
    }

    return Column(
      children: [
        CollapsibleBrandedHeader(
          title: context.s.keywordsTabTitle,
          subtitle: context.s.keywordsTabSubtitle,
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
                fieldKey: const ValueKey(WidgetKeys.searchFieldKeywords),
                submitKey: const ValueKey(WidgetKeys.searchSubmitKeywords),
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

  Widget _body(KeywordsViewModel vm) {
    if (vm.isLoading) {
      return StateView.loading(message: context.s.keywordsLoading);
    }
    if (vm.errorMessage.isNotEmpty) {
      return StateView.error(vm.errorMessage,
          title: context.s.somethingWentWrong,
          retryLabel: context.s.tryAgain,
          onRetry: () => vm.search(vm.currentTopic));
    }
    if (vm.keywords.isEmpty) {
      // After a search that returned nothing, show the "no results" state.
      if (vm.currentTopic.isNotEmpty) {
        return StateView.empty(
          icon: Icons.search_off_rounded,
          title: context.s.noResultsTitle,
          message: context.s.noResultsMessage(vm.currentTopic),
        );
      }
      return StateView.empty(
        icon: Icons.tag_rounded,
        title: context.s.keywordsEmptyTitle,
        message: context.s.keywordsEmptyMessage,
      );
    }

    final keywords = vm.keywords;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        // Trending keywords as chips (top 8)
        SectionCard(
          key: const ValueKey(WidgetKeys.keywordsStats),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                  title: context.s.keywordsTrending,
                  icon: Icons.local_fire_department_rounded),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: keywords.take(8).map((k) {
                  return ActionChip(
                    backgroundColor: AppColors.primarySoft,
                    side: BorderSide.none,
                    label: Text(k.key,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5)),
                    onPressed: () => _open(k.key),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(context.s.keywordsFrequency,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: keywords.asMap().entries.map((e) {
              final k = e.value;
              return _bar(k.key, k.value, vm.maxCount,
                  barKey: e.key == 0
                      ? const ValueKey(WidgetKeys.keywordListFirst)
                      : null);
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _open(String keyword) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KeywordDetailScreen(keyword: keyword)),
    );
  }

  Widget _bar(String name, int count, int maxCount, {Key? barKey}) {
    final fraction = (count / maxCount).clamp(0.05, 1.0);
    return InkWell(
      key: barKey,
      onTap: () => _open(name),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text('$count',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.violet)),
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
                    const AlwaysStoppedAnimation<Color>(AppColors.violet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
