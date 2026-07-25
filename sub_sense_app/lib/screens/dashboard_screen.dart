import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/card_container.dart';
import '../widgets/health_gauge.dart';
import '../widgets/money_text.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getHeadline(int score) {
    if (score >= 75) return 'Mostly in good shape.';
    if (score >= 50) return 'A few leaks worth plugging.';
    return 'Several leaks draining your money.';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final score = provider.baseHealthScore;
    final headline = _getHeadline(score);

    final totalSubs = provider.subscriptions.length;
    final needAttention = provider.subscriptions
        .where((s) => s.recommendedAction != 'Keep')
        .length;

    // Highest price hike info
    final hikedSubs = provider.subscriptions
        .where((s) => s.priceChange?.increased == true)
        .toList();
    hikedSubs.sort((a, b) => (b.priceChange?.percentChange ?? 0)
        .compareTo(a.priceChange?.percentChange ?? 0));
    final topHike = hikedSubs.isNotEmpty ? hikedSubs.first : null;

    // Duplicate services
    final duplicateSubs = provider.subscriptions
        .where((s) => s.category == 'Duplicate')
        .toList();

    // Cancel recommendations
    final cancelSubs = provider.subscriptions
        .where((s) => s.recommendedAction == 'Cancel')
        .toList();
    final cancelSavings =
        cancelSubs.fold(0.0, (sum, s) => sum + s.currentAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1024),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FINANCIAL HEALTH',
                style: AppTypography.eyebrow(color: AppColors.signalGreen),
              ),
              const SizedBox(height: 8),

              // Hero 2-Column Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isNarrow = constraints.maxWidth < 720;
                  Widget gaugeWidget = HealthGauge(score: score, size: 220);

                  Widget statsWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: AppTypography.headlineLarge(color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on analysis of ${provider.summary['total_transactions_found'] ?? 84} transactions in your bank statement.',
                        style: AppTypography.bodyMedium(color: AppColors.slate),
                      ),
                      const SizedBox(height: 28),

                      // 4 Stat Pairs Grid
                      Wrap(
                        spacing: 32,
                        runSpacing: 20,
                        children: [
                          _StatPair(
                            label: 'Monthly Leakage',
                            child: MoneyText(
                              amount: provider.monthlyLeakage,
                              size: MoneySize.medium,
                              color: AppColors.coral,
                            ),
                          ),
                          _StatPair(
                            label: 'Potential Savings',
                            child: MoneyText(
                              amount: provider.potentialMonthlySavings,
                              size: MoneySize.medium,
                              color: AppColors.signalGreen,
                            ),
                          ),
                          _StatPair(
                            label: 'Subscriptions',
                            child: Text(
                              '$totalSubs detected',
                              style: AppTypography.monoMedium(
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          _StatPair(
                            label: 'Need Attention',
                            child: Text(
                              '$needAttention flagged',
                              style: AppTypography.monoMedium(
                                color: needAttention > 0
                                    ? AppColors.amber
                                    : AppColors.signalGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        Center(child: gaugeWidget),
                        const SizedBox(height: 32),
                        statsWidget,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      gaugeWidget,
                      const SizedBox(width: 48),
                      Expanded(child: statsWidget),
                    ],
                  );
                },
              ),

              const SizedBox(height: 48),

              // Row of 3 Flag Cards
              Text(
                'Key Findings',
                style: AppTypography.titleLarge(color: AppColors.ink),
              ),
              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  bool stackCards = constraints.maxWidth < 800;

                  List<Widget> cards = [
                    // Flag Card 1: Price Increases
                    Expanded(
                      flex: stackCards ? 0 : 1,
                      child: CardContainer(
                        backgroundColor: AppColors.coral.withValues(alpha: 0.08),
                        borderColor: AppColors.coral.withValues(alpha: 0.3),
                        onTap: () => provider.setActiveTab(2), // Subscriptions tab
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  color: AppColors.coral,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Price Increase Detected',
                                  style: AppTypography.labelBold(
                                    color: AppColors.coral,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${hikedSubs.length} Subscription${hikedSubs.length == 1 ? '' : 's'} Hiked',
                              style: AppTypography.titleLarge(
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topHike != null
                                  ? '${topHike.merchant} +${topHike.priceChange?.percentChange}% (₹${topHike.priceChange?.amountChange.toInt()})'
                                  : 'No silent price hikes found',
                              style: AppTypography.bodySmall(
                                color: AppColors.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (stackCards) const SizedBox(height: 16) else const SizedBox(width: 16),

                    // Flag Card 2: Duplicate Services
                    Expanded(
                      flex: stackCards ? 0 : 1,
                      child: CardContainer(
                        backgroundColor: AppColors.amber.withValues(alpha: 0.08),
                        borderColor: AppColors.amber.withValues(alpha: 0.3),
                        onTap: () => provider.setActiveTab(2), // Subscriptions tab
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.content_copy_rounded,
                                  color: AppColors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Duplicate Services',
                                  style: AppTypography.labelBold(
                                    color: AppColors.amber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${duplicateSubs.length} Overlapping Service${duplicateSubs.length == 1 ? '' : 's'}',
                              style: AppTypography.titleLarge(
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              duplicateSubs.isNotEmpty
                                  ? duplicateSubs.map((s) => s.merchant).join(', ')
                                  : 'YouTube Premium & Netflix',
                              style: AppTypography.bodySmall(
                                color: AppColors.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (stackCards) const SizedBox(height: 16) else const SizedBox(width: 16),

                    // Flag Card 3: Recommended to Cancel
                    Expanded(
                      flex: stackCards ? 0 : 1,
                      child: CardContainer(
                        backgroundColor: AppColors.paperDim,
                        borderColor: AppColors.line,
                        onTap: () => provider.setActiveTab(4), // Actions tab
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.cancel_outlined,
                                  color: AppColors.slate,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Recommended to Cancel',
                                  style: AppTypography.labelBold(
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${cancelSubs.length} Subscription${cancelSubs.length == 1 ? '' : 's'}',
                              style: AppTypography.titleLarge(
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Save up to ',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.slate,
                                  ),
                                ),
                                MoneyText(
                                  amount: cancelSavings,
                                  size: MoneySize.small,
                                  color: AppColors.signalGreen,
                                ),
                                Text(
                                  ' / mo',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];

                  return stackCards ? Column(children: cards) : Row(children: cards);
                },
              ),

              const SizedBox(height: 48),

              // Bottom Call to Action Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => provider.setActiveTab(3), // Simulator Tab
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: Text(
                      'Try the savings simulator',
                      style: AppTypography.labelBold(color: AppColors.paper),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => provider.setActiveTab(2), // Subscriptions Tab
                    icon: const Icon(Icons.list_alt_rounded, size: 18),
                    label: Text(
                      'View all subscriptions',
                      style: AppTypography.labelBold(color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPair extends StatelessWidget {
  final String label;
  final Widget child;

  const _StatPair({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.eyebrow(color: AppColors.slate).copyWith(
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
