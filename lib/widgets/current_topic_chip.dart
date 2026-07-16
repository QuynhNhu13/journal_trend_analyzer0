import 'package:flutter/material.dart';

import '../l10n/locale_provider.dart';

/// A pill shown on the branded (pink) header of the Home / Journals / Keywords
/// tabs that surfaces the shared research topic, making it obvious the three
/// search bars are synced. The ✕ button clears the topic.
///
/// Styled to match the translucent-white chips already used on the brand
/// gradient header so it looks consistent across all three tabs.
class CurrentTopicChip extends StatelessWidget {
  final String topic;
  final VoidCallback onClear;

  const CurrentTopicChip({
    super.key,
    required this.topic,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                context.s.currentTopicLabel(topic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // 44×44 hit target (accessibility) with the same small circular
            // icon look.
            IconButton(
              onPressed: onClear,
              tooltip: context.s.clearTopicTooltip,
              iconSize: 15,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
