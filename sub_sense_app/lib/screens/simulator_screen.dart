import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/card_container.dart';
import '../widgets/health_gauge.dart';
import '../widgets/money_text.dart';

class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);

    // Only subscriptions with Downgrade or Cancel recommendation appear in simulator
    final actionableSubs = provider.subscriptions
        .where((s) => s.recommendedAction != 'Keep')
        .toList();

    final baseScore = provider.baseHealthScore;
    final simulatedScore = provider.simulatedHealthScore;
    final scoreDelta = simulatedScore - baseScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1024),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INTERACTIVE TOOL',
                style: AppTypography.eyebrow(color: AppColors.signalGreen),
              ),
              const SizedBox(height: 8),
              Text(
                'Simulate your savings',
                style: AppTypography.headlineLarge(color: AppColors.ink),
              ),
              const SizedBox(height: 12),
              Text(
                'Toggle recommended actions to see real-time impact on your Financial Health Score and monthly cash flow.',
                style: AppTypography.bodyLarge(color: AppColors.slate),
              ),
              const SizedBox(height: 36),

              // Two-Column Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isNarrow = constraints.maxWidth < 768;

                  Widget checklistWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Actionable Recommendations',
                            style: AppTypography.titleLarge(
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '${actionableSubs.length} items',
                            style: AppTypography.bodySmall(
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (actionableSubs.isEmpty) ...[
                        CardContainer(
                          child: Text(
                            'No actionable leaks detected. All subscriptions are marked as Keep!',
                            style: AppTypography.bodyMedium(
                              color: AppColors.slate,
                            ),
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: actionableSubs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sub = actionableSubs[index];
                            final isChecked = provider.simulatedCancelledIds
                                .contains(sub.id);

                            return CardContainer(
                              backgroundColor: isChecked
                                  ? AppColors.paperDim
                                  : AppColors.paper,
                              borderColor: isChecked
                                  ? AppColors.ink
                                  : AppColors.line,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              onTap: () =>
                                  provider.toggleSimulatorAction(sub.id),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: AppColors.ink,
                                    onChanged: (_) => provider
                                        .toggleSimulatorAction(sub.id),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${sub.recommendedAction} ${sub.merchant}',
                                          style: AppTypography.labelBold(
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          sub.actionReason,
                                          style: AppTypography.bodySmall(
                                            color: AppColors.slate,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      MoneyText(
                                        amount: sub.monthlySaving,
                                        size: MoneySize.small,
                                        color: AppColors.signalGreen,
                                      ),
                                      Text(
                                        '/ mo',
                                        style: AppTypography.monoSmall(
                                          color: AppColors.slate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  );

                  Widget darkResultPanel = Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Live Recomputed Gauge
                        HealthGauge(
                          score: simulatedScore,
                          size: 140,
                          animate: true,
                        ),
                        const SizedBox(height: 16),

                        // Score Delta Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scoreDelta > 0
                                ? AppColors.signalGreen.withValues(alpha: 0.2)
                                : AppColors.paperDim.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            scoreDelta > 0
                                ? '↑ +$scoreDelta from $baseScore'
                                : 'Baseline score: $baseScore',
                            style: AppTypography.monoSmall(
                              color: scoreDelta > 0
                                  ? AppColors.signalGreen
                                  : AppColors.paper,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Divider(color: AppColors.inkSoft, height: 1),
                        const SizedBox(height: 24),

                        // Monthly Savings Figure
                        Text(
                          'MONTHLY SAVINGS',
                          style: AppTypography.eyebrow(
                            color: AppColors.slate,
                          ).copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        MoneyText(
                          amount: provider.simulatedMonthlySavings,
                          size: MoneySize.large,
                          color: AppColors.paper,
                        ),

                        const SizedBox(height: 20),

                        // Annual Savings Figure
                        Text(
                          'ANNUAL SAVINGS',
                          style: AppTypography.eyebrow(
                            color: AppColors.slate,
                          ).copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        MoneyText(
                          amount: provider.simulatedAnnualSavings,
                          size: MoneySize.medium,
                          color: AppColors.signalGreen,
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.signalGreen,
                              foregroundColor: AppColors.paper,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                provider.setActiveTab(4), // Jumps to Actions
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 16),
                            label: Text(
                              'View Action Plan',
                              style: AppTypography.labelBold(
                                color: AppColors.paper,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        checklistWidget,
                        const SizedBox(height: 32),
                        darkResultPanel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: checklistWidget),
                      const SizedBox(width: 32),
                      Expanded(flex: 2, child: darkResultPanel),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
