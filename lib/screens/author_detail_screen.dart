import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/locale_provider.dart';
import '../models/publication.dart';
import '../providers/author_detail_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

class AuthorDetailScreen extends StatefulWidget {
  final String authorId;
  final String authorName;
  final String topic;

  const AuthorDetailScreen({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.topic,
  });

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthorDetailProvider>(context, listen: false)
          .fetchDetail(widget.authorId, widget.topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthorDetailProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(provider),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthorDetailProvider provider) {
    String initials = "";
    final parts = widget.authorName
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

    final author = provider.author;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.brand,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                author?.name ?? widget.authorName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (author?.institution != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      author!.institution!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (author != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric("H-INDEX", "${author.hIndex ?? '-'}"),
                    Container(width: 1, height: 30, color: Colors.white24),
                    _buildMetric("CITATIONS", "${author.citedByCount}"),
                    Container(width: 1, height: 30, color: Colors.white24),
                    _buildMetric("WORKS", "${author.worksCount}"),
                  ],
                ),
              )
            else if (provider.isLoading)
              const SizedBox(height: 52),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(AuthorDetailProvider provider) {
    if (provider.isLoading) {
      return StateView.loading(message: 'Loading profile and works...');
    }

    if (provider.errorMessage.isNotEmpty) {
      return StateView.error(
        context.s.somethingWentWrong,
        onRetry: () => provider.fetchDetail(widget.authorId, widget.topic),
      );
    }

    final papers = provider.publications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            "PUBLICATIONS ON TOPIC (${papers.length})",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (papers.isEmpty)
          Expanded(
            child: StateView.empty(
              icon: Icons.article_rounded,
              title: 'No publications',
              message: 'No publications found for this author on this topic.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: papers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildPublicationCard(context, papers[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPublicationCard(BuildContext context, Publication paper) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(publication: paper),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    paper.type.isEmpty ? 'Article' : _capitalize(paper.type),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  if (paper.openAccessStatus.isNotEmpty &&
                      paper.openAccessStatus != 'closed') ...[
                    const SizedBox(width: 8),
                    Container(width: 1, height: 12, color: AppColors.border),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.emerald),
                    const SizedBox(width: 4),
                    const Text(
                      'Open access',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                paper.title.isEmpty ? context.s.untitledWork : paper.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (paper.authors.isNotEmpty) ...[
                Text(
                  _formatAuthors(paper.authors),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                "${paper.journal.isNotEmpty ? paper.journal : 'Unknown Journal'} (${paper.year})",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.faint),
                  const SizedBox(width: 6),
                  Text(
                    "${paper.citationCount} Citations",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String _formatAuthors(List<String> authors) {
    if (authors.length <= 3) return authors.join(", ");
    return "${authors.take(3).join(", ")} et al.";
  }
}
