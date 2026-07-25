import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/card_container.dart';
import '../widgets/health_gauge.dart';
import '../widgets/money_text.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  String _actionFilter = 'All'; // 'All', 'Cancel', 'Downgrade'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);

    final actionableSubs = provider.subscriptions
        .where((s) => s.recommendedAction != 'Keep')
        .toList();

    final filteredSubs = actionableSubs.where((s) {
      if (_actionFilter == 'All') return true;
      return s.recommendedAction.toLowerCase() == _actionFilter.toLowerCase();
    }).toList();

    final baseScore = provider.baseHealthScore;
    final simulatedScore = provider.simulatedHealthScore;
    final scoreDelta = simulatedScore - baseScore;
    final selectedCount = provider.simulatedCancelledIds.length;
    final totalActionable = actionableSubs.length;

    final monthlyGoal = provider.monthlySavingsGoal;
    final simulatedMonthlySavings = provider.simulatedMonthlySavings;
    final goalProgress = (monthlyGoal > 0)
        ? (simulatedMonthlySavings / monthlyGoal).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HERO HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.signalGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tune_rounded, size: 12, color: AppColors.signalGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    'WHAT-IF SAVINGS SIMULATOR',
                                    style: AppTypography.eyebrow(color: AppColors.signalGreen).copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Interactive Leak Simulator',
                          style: AppTypography.headlineLarge(color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toggle proposed actions below to simulate real-time impact on your Financial Health Score and monthly cash flow.',
                          style: AppTypography.bodyMedium(color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.paperDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.checklist_rounded, size: 16, color: AppColors.ink),
                        const SizedBox(width: 8),
                        Text(
                          '$selectedCount of $totalActionable Leaks Actioned',
                          style: AppTypography.labelBold(color: AppColors.ink).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  bool isNarrow = constraints.maxWidth < 840;

                  Widget checklistWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ACTION BAR & FILTERS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _FilterChip(
                                label: 'All ($totalActionable)',
                                isSelected: _actionFilter == 'All',
                                onTap: () => setState(() => _actionFilter = 'All'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Cancel Only',
                                isSelected: _actionFilter == 'Cancel',
                                onTap: () => setState(() => _actionFilter = 'Cancel'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Downgrade Only',
                                isSelected: _actionFilter == 'Downgrade',
                                onTap: () => setState(() => _actionFilter = 'Downgrade'),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  backgroundColor: AppColors.signalGreen.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: provider.selectAllSimulatorActions,
                                icon: const Icon(Icons.done_all_rounded, size: 14, color: AppColors.signalGreen),
                                label: Text(
                                  'Select All',
                                  style: AppTypography.labelBold(color: AppColors.signalGreen).copyWith(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  backgroundColor: AppColors.paperDim,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: provider.resetSimulatorActions,
                                icon: const Icon(Icons.restart_alt_rounded, size: 14, color: AppColors.slate),
                                label: Text(
                                  'Reset',
                                  style: AppTypography.labelBold(color: AppColors.slate).copyWith(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (actionableSubs.isEmpty) ...[
                        CardContainer(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.verified_user_rounded, color: AppColors.signalGreen, size: 36),
                                const SizedBox(height: 12),
                                Text(
                                  'No actionable leaks detected!',
                                  style: AppTypography.titleLarge(color: AppColors.ink),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All subscriptions are currently optimized and marked as Keep.',
                                  style: AppTypography.bodySmall(color: AppColors.slate),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredSubs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sub = filteredSubs[index];
                            final isChecked = provider.simulatedCancelledIds.contains(sub.id);

                            Color actionColor = AppColors.amber;
                            if (sub.recommendedAction == 'Cancel') {
                              actionColor = AppColors.coral;
                            } else if (sub.recommendedAction == 'Downgrade') {
                              actionColor = AppColors.amber;
                            } else if (sub.recommendedAction == 'Renegotiate') {
                              actionColor = const Color(0xFF1E88E5);
                            }

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isChecked ? AppColors.paperDim : AppColors.paper,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isChecked ? AppColors.ink : AppColors.line,
                                  width: isChecked ? 2 : 1,
                                ),
                                boxShadow: isChecked
                                    ? [
                                        BoxShadow(
                                          color: AppColors.ink.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              child: InkWell(
                                onTap: () => provider.toggleSimulatorAction(sub.id),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    children: [
                                      Transform.scale(
                                        scale: 1.1,
                                        child: Checkbox(
                                          value: isChecked,
                                          activeColor: AppColors.ink,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (_) => provider.toggleSimulatorAction(sub.id),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: actionColor.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    sub.recommendedAction.toUpperCase(),
                                                    style: AppTypography.eyebrow(color: actionColor).copyWith(fontSize: 10),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  sub.merchant,
                                                  style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              sub.actionReason,
                                              style: AppTypography.bodySmall(color: AppColors.slate),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          MoneyText(
                                            amount: sub.monthlySaving,
                                            size: MoneySize.medium,
                                            color: AppColors.signalGreen,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Save / month',
                                            style: AppTypography.monoSmall(color: AppColors.slate).copyWith(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SIMULATED HEALTH SCORE',
                          style: AppTypography.eyebrow(color: AppColors.paper.withValues(alpha: 0.6)).copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 16),

                        HealthGauge(
                          score: simulatedScore,
                          size: 140,
                          animate: true,
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: scoreDelta > 0
                                ? AppColors.signalGreen.withValues(alpha: 0.2)
                                : AppColors.paper.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                scoreDelta > 0 ? Icons.trending_up_rounded : Icons.horizontal_rule_rounded,
                                size: 14,
                                color: scoreDelta > 0 ? const Color.fromARGB(255, 32, 140, 109) : AppColors.paper,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                scoreDelta > 0
                                    ? '+$scoreDelta pts improvement (Base: $baseScore)'
                                    : 'Baseline Score: $baseScore pts',
                                style: AppTypography.monoSmall(
                                  color: scoreDelta > 0 ? const Color.fromARGB(255, 32, 140, 109) : AppColors.paper,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Divider(color: AppColors.paper.withValues(alpha: 0.12), height: 1),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MONTHLY RECOVERED',
                                  style: AppTypography.eyebrow(color: AppColors.paper.withValues(alpha: 0.6)).copyWith(fontSize: 9),
                                ),
                                const SizedBox(height: 4),
                                MoneyText(
                                  amount: simulatedMonthlySavings,
                                  size: MoneySize.large,
                                  color: AppColors.paper,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '1-YEAR SAVINGS',
                                  style: AppTypography.eyebrow(color: AppColors.paper.withValues(alpha: 0.6)).copyWith(fontSize: 9),
                                ),
                                const SizedBox(height: 4),
                                MoneyText(
                                  amount: provider.simulatedAnnualSavings,
                                  size: MoneySize.medium,
                                  color: AppColors.signalGreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // GOAL PROGRESS BAR
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Savings Target Progress',
                                  style: AppTypography.monoSmall(color: AppColors.paper.withValues(alpha: 0.8)).copyWith(fontSize: 11),
                                ),
                                Text(
                                  '${(goalProgress * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.labelBold(color: AppColors.signalGreen).copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: goalProgress,
                                minHeight: 6,
                                backgroundColor: AppColors.paper.withValues(alpha: 0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.signalGreen),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Goal: ₹${monthlyGoal.toStringAsFixed(0)} / mo',
                              style: AppTypography.monoSmall(color: AppColors.paper.withValues(alpha: 0.5)).copyWith(fontSize: 10),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.signalGreen,
                              foregroundColor: AppColors.paper,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => provider.setTab(4),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: Text(
                              'View Action Plan',
                              style: AppTypography.labelBold(color: AppColors.paper).copyWith(fontSize: 14),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.paperDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.ink : AppColors.line),
        ),
        child: Text(
          label,
          style: AppTypography.labelBold(
            color: isSelected ? AppColors.paper : AppColors.ink,
          ).copyWith(fontSize: 12),
        ),
      ),
    );
  }
}
