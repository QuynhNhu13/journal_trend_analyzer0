import 'package:flutter/material.dart';
import '../l10n/locale_provider.dart';
import '../models/journal_stat.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'journal_detail_screen.dart';

class AllJournalsScreen extends StatelessWidget {
  final List<JournalStat> journals;
  final String topic;

  const AllJournalsScreen({
    super.key,
    required this.journals,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.s.allJournalsTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: journals.length,
        itemBuilder: (context, i) {
          final j = journals[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: RankBadge(rank: i + 1),
                title: Text(j.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                  '${context.s.journalRankSubtitle(j.publicationCount, j.averageCitations.toStringAsFixed(1))}${j.issn.isNotEmpty ? '\nISSN: ${j.issn}' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JournalDetailScreen(journal: j)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
