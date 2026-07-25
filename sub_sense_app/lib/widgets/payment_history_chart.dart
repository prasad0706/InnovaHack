import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'money_text.dart';

class PaymentHistoryChart extends StatelessWidget {
  final List<PaymentHistoryItem> history;
  final bool hasPriceHike;

  const PaymentHistoryChart({
    super.key,
    required this.history,
    required this.hasPriceHike,
  });

  String _formatMonth(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM').format(dt).toUpperCase();
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxAmount = history.fold(
      0.0,
      (max, item) => item.amount > max ? item.amount : max,
    );
    if (maxAmount == 0) maxAmount = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAYMENT HISTORY',
              style: AppTypography.eyebrow(color: AppColors.slate).copyWith(
                fontSize: 10,
              ),
            ),
            Text(
              'Last ${history.length} cycles',
              style: AppTypography.bodySmall(color: AppColors.slate),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(history.length, (index) {
              final item = history[index];
              final isLatest = index == history.length - 1;
              final heightPct = (item.amount / maxAmount).clamp(0.15, 1.0);

              // Recency opacity fading rule: older bars fade 35-75%, latest is 100%
              double opacity = 0.35 + (0.40 * (index / (history.length > 1 ? history.length - 1 : 1)));
              if (isLatest) opacity = 1.0;

              Color barColor = AppColors.ink.withValues(alpha: opacity);
              if (isLatest && hasPriceHike) {
                barColor = AppColors.coral;
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MoneyText(
                    amount: item.amount,
                    size: MoneySize.small,
                    color: isLatest && hasPriceHike
                        ? AppColors.coral
                        : AppColors.ink,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 28,
                    height: 55 * heightPct,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatMonth(item.date),
                    style: AppTypography.monoSmall(
                      color: isLatest ? AppColors.ink : AppColors.slate,
                    ).copyWith(
                      fontWeight:
                          isLatest ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
