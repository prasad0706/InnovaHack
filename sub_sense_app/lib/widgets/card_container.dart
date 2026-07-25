import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CardContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const CardContainer({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.paperDim,
    this.borderColor = AppColors.line,
    this.padding = const EdgeInsets.all(20.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          hoverColor: AppColors.line.withValues(alpha: 0.3),
          child: content,
        ),
      );
    }

    return content;
  }
}
