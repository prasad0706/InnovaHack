import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/card_container.dart';
import '../widgets/health_gauge.dart';
import '../widgets/money_text.dart';
import '../widgets/user_profile_modal.dart';
import '../widgets/transaction_ledger_modal.dart';

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

    final hikedSubs = provider.subscriptions
        .where((s) => s.priceChange?.increased == true)
        .toList();
    hikedSubs.sort((a, b) => (b.priceChange?.percentChange ?? 0)
        .compareTo(a.priceChange?.percentChange ?? 0));
    final topHike = hikedSubs.isNotEmpty ? hikedSubs.first : null;

    final duplicateSubs = provider.subscriptions
        .where((s) => s.category == 'Duplicate')
        .toList();

    final cancelSubs = provider.subscriptions
        .where((s) => s.recommendedAction == 'Cancel')
        .toList();
    final cancelSavings =
        cancelSubs.fold(0.0, (sum, s) => sum + s.currentAmount);

    double goalProgress = (provider.potentialMonthlySavings / provider.monthlySavingsGoal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP WELCOME & GOAL BANNER
              CardContainer(
                backgroundColor: AppColors.paperDim,
                borderColor: AppColors.line,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.ink,
                      child: Icon(Icons.person_rounded, color: AppColors.paper, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Welcome back, ${provider.userName}!',
                                style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.signalGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  provider.accountLabel,
                                  style: AppTypography.monoSmall(color: AppColors.signalGreen).copyWith(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: goalProgress,
                                    minHeight: 6,
                                    backgroundColor: AppColors.line,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.signalGreen),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Goal: ₹${provider.potentialMonthlySavings.toStringAsFixed(0)} / ₹${provider.monthlySavingsGoal.toStringAsFixed(0)}',
                                style: AppTypography.monoSmall(color: AppColors.slate).copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => UserProfileModal.show(context),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: Text('Edit Target', style: AppTypography.monoSmall(color: AppColors.ink).copyWith(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // MAIN SINGLE VIEW DASHBOARD GRID
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isNarrow = constraints.maxWidth < 840;

                    Widget mainGaugePanel = Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'FINANCIAL HEALTH SCORE',
                                style: AppTypography.eyebrow(color: AppColors.signalGreen).copyWith(fontSize: 10),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => TransactionLedgerModal.show(context),
                                icon: const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.signalGreen),
                                label: Text(
                                  'View Statement Ledger',
                                  style: AppTypography.monoSmall(color: AppColors.signalGreen).copyWith(
                                    decoration: TextDecoration.underline,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              HealthGauge(score: score, size: 170),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      headline,
                                      style: AppTypography.headlineMedium(color: AppColors.ink).copyWith(fontSize: 20),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Based on analysis of ${provider.summary['total_transactions_found'] ?? provider.allTransactions.length} parsed transactions.',
                                      style: AppTypography.bodySmall(color: AppColors.slate),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.line, height: 1),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatPair(
                                label: 'Monthly Leakage',
                                child: MoneyText(
                                  amount: provider.monthlyLeakage,
                                  size: MoneySize.small,
                                  color: AppColors.coral,
                                ),
                              ),
                              _StatPair(
                                label: 'Potential Savings',
                                child: MoneyText(
                                  amount: provider.potentialMonthlySavings,
                                  size: MoneySize.small,
                                  color: AppColors.signalGreen,
                                ),
                              ),
                              _StatPair(
                                label: 'Subscriptions',
                                child: Text(
                                  '$totalSubs active',
                                  style: AppTypography.monoSmall(color: AppColors.ink).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              _StatPair(
                                label: 'Need Attention',
                                child: Text(
                                  '$needAttention flagged',
                                  style: AppTypography.monoSmall(
                                    color: needAttention > 0 ? AppColors.amber : AppColors.signalGreen,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.ink,
                                    foregroundColor: AppColors.paper,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => provider.setTab(3),
                                  icon: const Icon(Icons.tune_rounded, size: 16),
                                  label: Text(
                                    'Savings Simulator',
                                    style: AppTypography.labelBold(color: AppColors.paper).copyWith(fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    side: const BorderSide(color: AppColors.line, width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => provider.setTab(2),
                                  icon: const Icon(Icons.list_alt_rounded, size: 16),
                                  label: Text(
                                    'View Subscriptions',
                                    style: AppTypography.labelBold(color: AppColors.ink).copyWith(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    Widget keyFindingsPanel = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KEY FINDINGS & ALERTS',
                          style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 12),

                        CardContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: AppColors.coral.withValues(alpha: 0.08),
                          borderColor: AppColors.coral.withValues(alpha: 0.3),
                          onTap: () => provider.setTab(2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.trending_up_rounded, color: AppColors.coral, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Price Hike Alerts',
                                    style: AppTypography.labelBold(color: AppColors.coral).copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${hikedSubs.length} Subscription${hikedSubs.length == 1 ? '' : 's'} Hiked',
                                style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topHike != null
                                    ? '${topHike.merchant} +${topHike.priceChange?.percentChange}% (₹${topHike.priceChange?.amountChange.toInt()})'
                                    : 'No silent price hikes found',
                                style: AppTypography.bodySmall(color: AppColors.slate),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        CardContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: AppColors.amber.withValues(alpha: 0.08),
                          borderColor: AppColors.amber.withValues(alpha: 0.3),
                          onTap: () => provider.setTab(2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.content_copy_rounded, color: AppColors.amber, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Duplicate Services',
                                    style: AppTypography.labelBold(color: AppColors.amber).copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${duplicateSubs.length} Overlapping Service${duplicateSubs.length == 1 ? '' : 's'}',
                                style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                duplicateSubs.isNotEmpty
                                    ? duplicateSubs.map((s) => s.merchant).join(', ')
                                    : 'YouTube Premium & Netflix',
                                style: AppTypography.bodySmall(color: AppColors.slate),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        CardContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: AppColors.paperDim,
                          borderColor: AppColors.line,
                          onTap: () => provider.setTab(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.cancel_outlined, color: AppColors.slate, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Action Recommended',
                                    style: AppTypography.labelBold(color: AppColors.slate).copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${cancelSubs.length} Plan${cancelSubs.length == 1 ? '' : 's'} to Action',
                                style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text('Save up to ', style: AppTypography.bodySmall(color: AppColors.slate)),
                                  MoneyText(
                                    amount: cancelSavings,
                                    size: MoneySize.small,
                                    color: AppColors.signalGreen,
                                  ),
                                  Text(' / mo', style: AppTypography.bodySmall(color: AppColors.slate)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            mainGaugePanel,
                            const SizedBox(height: 20),
                            keyFindingsPanel,
                          ],
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: mainGaugePanel),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: keyFindingsPanel),
                      ],
                    );
                  },
                ),
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
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
