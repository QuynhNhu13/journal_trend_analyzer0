import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/locale_provider.dart';
import '../models/author.dart';
import '../providers/top_author_provider.dart';
import '../providers/recent_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/topic_search_bar.dart';
import 'author_detail_screen.dart';

class TopAuthorScreen extends StatefulWidget {
  const TopAuthorScreen({super.key});

  @override
  State<TopAuthorScreen> createState() => _TopAuthorScreenState();
}

class _TopAuthorScreenState extends State<TopAuthorScreen> {
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
    Provider.of<TopAuthorProvider>(context, listen: false).search(text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TopAuthorProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          BrandedHeader(
            title: context.s.topAuthorsTitle,
            subtitle: provider.currentTopic.isNotEmpty
                ? context.s.topAuthorsSubtitleForTopic(provider.currentTopic)
                : context.s.topAuthorsSubtitleDefault,
            icon: Icons.people_alt_rounded,
            child: TopicSearchBar(
              hintText: context.s.topAuthorsSearchHint,
              initialValue: _currentSearchText,
              onSearch: _onSearch,
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(TopAuthorProvider provider) {
    if (provider.isLoading) {
      return StateView.loading(message: context.s.loadingAuthors);
    }

    if (provider.errorMessage.isNotEmpty) {
      return StateView.error(
        context.s.somethingWentWrong,
        onRetry: () => provider.search(provider.currentTopic),
      );
    }

    final authors = provider.authors;

    if (authors.isEmpty && provider.currentTopic.isNotEmpty) {
      return StateView.empty(
        icon: Icons.people_alt_rounded,
        title: context.s.noAuthorsTitle,
        message: context.s.noAuthorsMessage,
      );
    } else if (authors.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      itemCount: authors.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final author = authors[index];
        return _authorCard(context, index + 1, author);
      },
    );
  }

  Widget _authorCard(BuildContext context, int rank, TopAuthor author) {
    Color rankColor;
    if (rank == 1) {
      rankColor = AppColors.gold;
    } else if (rank == 2) {
      rankColor = AppColors.silver;
    } else if (rank == 3) {
      rankColor = AppColors.bronze;
    } else {
      rankColor = AppColors.faint;
    }

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  "$rank",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: rankColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: rankColor == AppColors.faint ? AppColors.muted : rankColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  author.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${author.worksCount}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.description_outlined, size: 16, color: AppColors.faint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
