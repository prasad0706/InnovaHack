import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class NavShell extends StatelessWidget {
  final Widget body;

  const NavShell({super.key, required this.body});

  static const List<String> tabTitles = [
    'Upload',
    'Health',
    'Subscriptions',
    'Simulator',
    'Actions',
    'AI Coach',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 1.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo & Tagline
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'SubSense',
                        style: AppTypography.headlineMedium(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'leak detector',
                        style: AppTypography.bodySmall(
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),

                  // Pill Navigation Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.paperDim,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.line, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(tabTitles.length, (index) {
                          final isLocked = index != 0 && !provider.isAnalyzed;
                          final isActive = provider.activeTabIndex == index;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                onTap: isLocked
                                    ? null
                                    : () => provider.setActiveTab(index),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.ink
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tabTitles[index],
                                        style: AppTypography.labelBold().copyWith(
                                          color: isActive
                                              ? AppColors.paper
                                              : (isLocked
                                                  ? AppColors.slate
                                                      .withValues(alpha: 0.4)
                                                  : AppColors.ink),
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (isLocked) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.lock_outline_rounded,
                                          size: 12,
                                          color: AppColors.slate
                                              .withValues(alpha: 0.4),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Screen Content Body
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}
