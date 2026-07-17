import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/widget_keys.dart';

/// A branded gradient header placed at the top of a screen body (not an AppBar).
///
/// Automatically shows a back button when the current route can be popped.
class BrandedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;

  /// When provided, a hamburger (menu) button is shown as the leading widget
  /// and the [icon] logo is hidden — used to open the app drawer from screens
  /// that live inside the main tabbed scaffold (e.g. Trends, Compare).
  final VoidCallback? onMenuTap;

  /// Optional content rendered below the title (e.g. a search field).
  final Widget? child;

  const BrandedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onMenuTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final Widget? lead = leading ??
        (onMenuTap != null
            ? _CircleIconButton(
                icon: Icons.menu_rounded,
                onTap: onMenuTap!,
              )
            : (canPop
                ? _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  )
                : null));

    // The menu button replaces the logo icon, mirroring the Dashboard header.
    final bool showIcon = icon != null && onMenuTap == null;

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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (lead != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: lead,
                    ),
                  if (showIcon) ...[
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (child != null) ...[const SizedBox(height: 18), child!],
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

/// A white rounded card used to group content consistently.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppDecorations.card(radius: radius),
      child: child,
    );
  }
}

/// Small icon + title row used as a heading inside cards/sections.
class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color color;

  const SectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rank badge for "top" lists with gold/silver/bronze treatment for the podium.
class RankBadge extends StatelessWidget {
  final int rank;
  final double size;

  const RankBadge({super.key, required this.rank, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final podium = rank <= 3;
    Color color;
    switch (rank) {
      case 1:
        color = AppColors.gold;
        break;
      case 2:
        color = AppColors.silver;
        break;
      case 3:
        color = AppColors.bronze;
        break;
      default:
        color = AppColors.primarySoft;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: podium
            ? LinearGradient(
                colors: [color.withValues(alpha: 0.95), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: podium ? null : AppColors.primarySoft,
        shape: BoxShape.circle,
        boxShadow: podium
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: podium
          ? const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20)
          : Text(
              "$rank",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
    );
  }
}

/// Consistent full-screen states: loading, error and empty.
class StateView {
  StateView._();

  /// Centers [child] but lets it scroll when it is taller than the available
  /// space (small screens, large system fonts, long error messages), so the
  /// state view never overflows on Android.
  static Widget _scrollableCenter(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }

  static Widget loading({String? message}) {
    return _scrollableCenter(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }

  static Widget error(
    String message, {
    VoidCallback? onRetry,
    String title = "Something went wrong",
    String retryLabel = "Try again",
  }) {
    return _scrollableCenter(
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 40, color: AppColors.danger),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const ValueKey(WidgetKeys.retryButton),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget empty({
    required IconData icon,
    required String title,
    String? message,
  }) {
    return _scrollableCenter(
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact pill showing an icon and label, used for metadata chips.
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const MetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
