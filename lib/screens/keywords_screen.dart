import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../viewmodels/keywords_view_model.dart';
import '../viewmodels/topic_provider.dart';
import '../widgets/common.dart';
import '../widgets/topic_search_bar.dart';
import 'keyword_detail_screen.dart';

/// Keywords tab (lab §4.6): keyword-based research analysis for the topic.
class KeywordsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const KeywordsScreen({super.key, this.onMenuTap});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
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

    if (topic.isNotEmpty && topic != _lastLoaded && !vm.isLoading) {
      _lastLoaded = topic;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<KeywordsViewModel>().search(topic);
      });
    }

    return Column(
      children: [
        BrandedHeader(
          title: 'Keywords',
          subtitle: 'Phân tích từ khóa',
          onMenuTap: widget.onMenuTap,
          child: TopicSearchBar(
            hintText: 'Nhập chủ đề để phân tích từ khóa',
            initialValue: vm.currentTopic.isEmpty ? topic : vm.currentTopic,
            onSearch: _search,
          ),
        ),
        Expanded(child: _body(vm)),
      ],
    );
  }

  Widget _body(KeywordsViewModel vm) {
    if (vm.isLoading) return StateView.loading(message: 'Đang tải từ khóa…');
    if (vm.errorMessage.isNotEmpty) {
      return StateView.error(vm.errorMessage,
          onRetry: () => vm.search(vm.currentTopic));
    }
    if (vm.keywords.isEmpty) {
      return StateView.empty(
        icon: Icons.tag_rounded,
        title: 'Chưa có dữ liệu từ khóa',
        message: 'Tìm một chủ đề để xem các từ khóa phổ biến.',
      );
    }

    final keywords = vm.keywords;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        // Trending keywords as chips (top 8)
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                  title: 'Từ khóa nổi bật',
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
        const Text('Tần suất từ khóa',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: keywords
                .map((k) => _bar(k.key, k.value, vm.maxCount))
                .toList(),
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

  Widget _bar(String name, int count, int maxCount) {
    final fraction = (count / maxCount).clamp(0.05, 1.0);
    return InkWell(
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
