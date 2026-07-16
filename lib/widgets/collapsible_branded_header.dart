import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../theme/app_theme.dart';

/// The pink brand header used on Home / Journals / Keywords, with an optional
/// collapse animation.
///
/// It is a plain widget placed above an `Expanded(body)` in a `Column` (exactly
/// like the stable non-collapsing layout) — no slivers, no `SliverAppBar` and no
/// `FlexibleSpaceBar`, so none of the layout/null-check pitfalls of those apply.
///
/// When [collapsed] is true, everything under the title row (subtitle, search
/// bar, topic chip, …) smoothly fades and shrinks away via [AnimatedCrossFade],
/// leaving just the title + hamburger. Screens flip [collapsed] based on scroll
/// direction, so pulling the list up brings the header back instantly.
class CollapsibleBrandedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Opens the app drawer; shown as a hamburger button (always visible).
  final VoidCallback? onMenuTap;

  /// Collapsible content shown under the title when expanded (search bar, chip…).
  final Widget? child;

  /// When true, only the title row is shown.
  final bool collapsed;

  const CollapsibleBrandedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuTap,
    this.child,
    this.collapsed = false,
  });

  static const Duration _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleRow(),
              AnimatedCrossFade(
                duration: _duration,
                sizeCurve: Curves.easeInOut,
                firstCurve: Curves.easeInOut,
                secondCurve: Curves.easeInOut,
                crossFadeState: collapsed
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                // Collapsed: nothing (zero height). Expanded: subtitle + content.
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ?child,
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleRow() {
    return Row(
      children: [
        if (onMenuTap != null) ...[
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onMenuTap,
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.menu_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Mixin for a [State] that flips a `headerCollapsed` flag from the vertical
/// scroll direction of its body. Wrap the scrolling body in a
/// `NotificationListener` for `UserScrollNotification` that calls [onBodyScroll],
/// and read [headerCollapsed] when building the header.
mixin HeaderCollapseMixin<T extends StatefulWidget> on State<T> {
  bool _headerCollapsed = false;
  bool get headerCollapsed => _headerCollapsed;

  bool onBodyScroll(UserScrollNotification notification) {
    // Ignore horizontal scrollables (e.g. the suggestion-chip row).
    if (notification.metrics.axis != Axis.vertical) return false;

    final direction = notification.direction;
    if (direction == ScrollDirection.reverse &&
        !_headerCollapsed &&
        // Only collapse when there is real content to scroll (don't collapse on
        // an overscroll bounce of a short empty/loading screen).
        notification.metrics.maxScrollExtent > 0) {
      setState(() => _headerCollapsed = true);
    } else if (direction == ScrollDirection.forward && _headerCollapsed) {
      setState(() => _headerCollapsed = false);
    }
    return false;
  }
}
