import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase/analytics_service.dart';
import '../l10n/locale_provider.dart';
import '../models/publication.dart';
import '../theme/app_theme.dart';
import '../utils/widget_keys.dart';
import '../widgets/common.dart';

class DetailScreen extends StatefulWidget {
  final Publication publication;

  const DetailScreen({super.key, required this.publication});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    // Analytics: view_publication (lab §5).
    AnalyticsService.instance.logViewPublication(
      title: widget.publication.title,
      year: widget.publication.year,
    );
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    if (!urlString.startsWith('http')) {
      urlString = 'https://doi.org/$urlString';
    }
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.publication;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.s.detailAppBarTitle,
            key: const ValueKey(WidgetKeys.publicationDetailTitle)),
        actions: [
          if (p.doi.isNotEmpty)
            IconButton(
              tooltip: context.s.openPaperTooltip,
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              onPressed: () => _launchUrl(p.doi),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildHero(context, p),
          const SizedBox(height: 16),
          _buildOverview(context, p),
          const SizedBox(height: 16),
          _buildMetrics(context, p),
          const SizedBox(height: 16),
          _buildTaxonomy(context, p),
          const SizedBox(height: 16),
          _buildAccessAndFunding(context, p),
          if (p.abstractText.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAbstract(context, p),
          ],
        ],
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, Publication p) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.title.isNotEmpty ? p.title : context.s.untitledWork,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p.year > 0)
                MetaChip(
                    icon: Icons.calendar_today_rounded,
                    label: "${p.year}",
                    color: AppColors.emerald),
              MetaChip(
                  icon: Icons.format_quote_rounded,
                  label: context.s.citationsChip(_compact(p.citationCount)),
                  color: AppColors.primary),
              if (p.type.isNotEmpty)
                MetaChip(
                    icon: Icons.category_rounded,
                    label: p.type,
                    color: AppColors.indigo),
              if (p.openAccessStatus.isNotEmpty)
                MetaChip(
                    icon: Icons.lock_open_rounded,
                    label: p.openAccessStatus,
                    color: AppColors.amber),
            ],
          ),
          if (p.doi.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(p.doi),
                icon: const Icon(Icons.description_rounded, size: 18),
                label: Text(context.s.readFullPaper),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Sections ────────────────────────────────────────────

  Widget _buildOverview(BuildContext context, Publication p) {
    final na = context.s.notAvailable;
    return _group(context.s.sectionOverview, Icons.info_outline_rounded, [
      _kv(context.s.fieldSource, p.journal.isNotEmpty ? p.journal : na,
          highlight: p.journal.isNotEmpty),
      _kvExpandable(context.s.fieldAuthors, p.authors),
      _kvExpandable(context.s.fieldInstitutions, p.institutions),
      _kv(context.s.fieldLanguage, p.language.isNotEmpty ? p.language : na),
    ]);
  }

  Widget _buildMetrics(BuildContext context, Publication p) {
    final na = context.s.notAvailable;
    return _group(context.s.sectionMetrics, Icons.insights_rounded, [
      _kv(context.s.fieldFwci, p.fwci > 0 ? p.fwci.toString() : na),
      _kv(context.s.fieldReferences, p.cites > 0 ? "${p.cites}" : "0"),
      _kv(context.s.fieldCitedBy, "${p.citationCount}", highlight: true),
      _kv(context.s.fieldRelatedWorks, "${p.relatedTo}"),
      if (p.doi.isNotEmpty)
        _kv(context.s.fieldDoi, p.doi,
            highlight: true, onTap: () => _launchUrl(p.doi)),
    ]);
  }

  Widget _buildTaxonomy(BuildContext context, Publication p) {
    final na = context.s.notAvailable;
    return _group(context.s.sectionTaxonomy, Icons.account_tree_rounded, [
      _kv(context.s.fieldTopic, p.topic.isNotEmpty ? p.topic : na,
          highlight: true),
      _kv(context.s.fieldSubfield, p.subfield.isNotEmpty ? p.subfield : na),
      _kv(context.s.fieldField, p.field.isNotEmpty ? p.field : na),
      _kv(context.s.fieldDomain, p.domain.isNotEmpty ? p.domain : na),
      _kv(context.s.fieldSdg, p.sdg.isNotEmpty ? p.sdg : na),
    ]);
  }

  Widget _buildAccessAndFunding(BuildContext context, Publication p) {
    final na = context.s.notAvailable;
    return _group(
        context.s.sectionAccessFunding, Icons.volunteer_activism_rounded, [
      _kv(context.s.fieldOpenAccess,
          p.openAccessStatus.isNotEmpty ? p.openAccessStatus : na),
      _kvExpandable(context.s.fieldFunders, p.funders),
      _kvExpandable(context.s.fieldAwards, p.awards),
    ]);
  }

  Widget _buildAbstract(BuildContext context, Publication p) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
              title: context.s.sectionAbstract, icon: Icons.notes_rounded),
          const SizedBox(height: 12),
          Text(
            p.abstractText,
            style: const TextStyle(
                fontSize: 14.5, height: 1.65, color: AppColors.body),
          ),
        ],
      ),
    );
  }

  // ─── Building blocks ─────────────────────────────────────

  Widget _group(String title, IconData icon, List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(const Divider(height: 22));
      }
    }
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title, icon: icon),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String label, String value,
      {bool highlight = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppColors.primary : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvExpandable(String label, List<String> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Expanded(child: ExpandableValue(items: items)),
      ],
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return "$n";
  }
}

/// Shows a comma-joined list of values, collapsing long lists behind a
/// "+N more" / "Show less" toggle.
class ExpandableValue extends StatefulWidget {
  final List<String> items;
  final int maxItemsToShow;

  const ExpandableValue({
    super.key,
    required this.items,
    this.maxItemsToShow = 5,
  });

  @override
  State<ExpandableValue> createState() => _ExpandableValueState();
}

class _ExpandableValueState extends State<ExpandableValue> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: AppColors.ink);
    const linkStyle = TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary);

    if (widget.items.isEmpty) {
      return Text(context.s.notAvailable, style: valueStyle);
    }

    final canToggle = widget.items.length > widget.maxItemsToShow;
    final visible = (!canToggle || _expanded)
        ? widget.items
        : widget.items.take(widget.maxItemsToShow).toList();

    final spans = <TextSpan>[
      TextSpan(text: visible.join(", "), style: valueStyle),
    ];
    if (canToggle) {
      spans.add(const TextSpan(text: "  "));
      spans.add(TextSpan(
        text: _expanded
            ? context.s.showLess
            : context.s.plusMore(widget.items.length - widget.maxItemsToShow),
        style: linkStyle,
      ));
    }

    return GestureDetector(
      onTap: canToggle ? () => setState(() => _expanded = !_expanded) : null,
      child: Text.rich(TextSpan(children: spans)),
    );
  }
}
