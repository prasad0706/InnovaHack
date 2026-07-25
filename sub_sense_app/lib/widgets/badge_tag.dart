import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BadgeType { priceHike, duplicate, cancel, downgrade, keep }

class BadgeTag extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;

  const BadgeTag({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  factory BadgeTag.priceHike(String text) {
    return BadgeTag(
      label: text,
      type: BadgeType.priceHike,
      icon: Icons.trending_up_rounded,
    );
  }

  factory BadgeTag.duplicate(String text) {
    return BadgeTag(
      label: text,
      type: BadgeType.duplicate,
      icon: Icons.content_copy_rounded,
    );
  }

  factory BadgeTag.cancel(String text) {
    return BadgeTag(
      label: text,
      type: BadgeType.cancel,
      icon: Icons.cancel_outlined,
    );
  }

  factory BadgeTag.downgrade(String text) {
    return BadgeTag(
      label: text,
      type: BadgeType.downgrade,
      icon: Icons.south_west_rounded,
    );
  }

  factory BadgeTag.keep(String text) {
    return BadgeTag(
      label: text,
      type: BadgeType.keep,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case BadgeType.priceHike:
      case BadgeType.cancel:
        bg = AppColors.coral.withValues(alpha: 0.12);
        fg = AppColors.coral;
        break;
      case BadgeType.duplicate:
      case BadgeType.downgrade:
        bg = AppColors.amber.withValues(alpha: 0.15);
        fg = AppColors.amber;
        break;
      case BadgeType.keep:
        bg = AppColors.signalGreen.withValues(alpha: 0.12);
        fg = AppColors.signalGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.bodySmall(color: fg).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
