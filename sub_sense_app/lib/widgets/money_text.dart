import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum MoneySize { small, medium, large }

class MoneyText extends StatelessWidget {
  final double amount;
  final MoneySize size;
  final Color? color;
  final bool showSign;

  const MoneyText({
    super.key,
    required this.amount,
    this.size = MoneySize.medium,
    this.color,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );

    String formatted = formatter.format(amount.abs());
    if (showSign && amount > 0) {
      formatted = '+ $formatted';
    } else if (amount < 0) {
      formatted = '- $formatted';
    }

    final textColor = color ?? AppColors.ink;

    TextStyle style;
    switch (size) {
      case MoneySize.large:
        style = AppTypography.monoLarge(color: textColor);
        break;
      case MoneySize.medium:
        style = AppTypography.monoMedium(color: textColor);
        break;
      case MoneySize.small:
        style = AppTypography.monoRegular(color: textColor);
        break;
    }

    return Text(
      formatted,
      style: style,
    );
  }
}
