import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/subscription_model.dart';
import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/card_container.dart';
import '../widgets/money_text.dart';
import '../widgets/cancellation_guide_modal.dart';

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  String _filter = 'All'; // 'All', 'Cancel', 'Downgrade', 'Keep'
  final Set<String> _completedActionIds = {};

  List<SubscriptionItem> _getSortedSubscriptions(List<SubscriptionItem> subs) {
    List<SubscriptionItem> list = List.from(subs);
    int getPriority(String action) {
      switch (action) {
        case 'Cancel':
          return 1;
        case 'Downgrade':
          return 2;
        default:
          return 3;
      }
    }

    list.sort((a, b) {
      int pA = getPriority(a.recommendedAction);
      int pB = getPriority(b.recommendedAction);
      if (pA != pB) return pA.compareTo(pB);
      return b.monthlySaving.compareTo(a.monthlySaving);
    });

    return list;
  }

  void _copyActionPlanToClipboard(BuildContext context, List<SubscriptionItem> sortedSubs, double totalAnnualSavings) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("=== SUBSENSE PRIORITIZED ACTION PLAN ===");
    buffer.writeln("Total Potential Annual Savings: ₹${totalAnnualSavings.toStringAsFixed(0)} / year\n");

    int index = 1;
    for (var s in sortedSubs) {
      if (s.recommendedAction != 'Keep') {
        final isDone = _completedActionIds.contains(s.id);
        buffer.writeln("$index. [${isDone ? 'COMPLETED' : 'PENDING'}] ${s.recommendedAction.toUpperCase()} ${s.merchant}");
        buffer.writeln("   Reason: ${s.actionReason}");
        buffer.writeln("   Annual Savings: ₹${(s.monthlySaving * 12).toStringAsFixed(0)}\n");
        index++;
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.signalGreen, size: 18),
            const SizedBox(width: 10),
            Text(
              'Action Plan copied to clipboard!',
              style: AppTypography.bodyMedium(color: AppColors.paper),
            ),
          ],
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final sortedSubs = _getSortedSubscriptions(provider.subscriptions);

    final actionableSubs = sortedSubs.where((s) => s.recommendedAction != 'Keep').toList();

    final filteredSubs = sortedSubs.where((s) {
      if (_filter == 'All') return true;
      return s.recommendedAction.toLowerCase() == _filter.toLowerCase();
    }).toList();

    double totalAnnualSavings = provider.subscriptions
        .where((s) => s.recommendedAction != 'Keep')
        .fold(0.0, (sum, s) => sum + (s.monthlySaving * 12));

    double completedSavings = actionableSubs
        .where((s) => _completedActionIds.contains(s.id))
        .fold(0.0, (sum, s) => sum + (s.monthlySaving * 12));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER ROW (COMPACT)
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.signalGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PRIORITIZED RECOVERY CENTER',
                                style: AppTypography.eyebrow(color: AppColors.signalGreen).copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Actionable Optimization Plan',
                          style: AppTypography.headlineMedium(color: AppColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Execute recommended actions to eliminate recurring payment leaks and lock in maximum annual savings.',
                          style: AppTypography.bodySmall(color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.paperDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.task_alt_rounded, size: 18, color: AppColors.signalGreen),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_completedActionIds.length} of ${actionableSubs.length} Actioned',
                              style: AppTypography.labelBold(color: AppColors.ink).copyWith(fontSize: 13),
                            ),
                            Text(
                              '₹${completedSavings.toStringAsFixed(0)} / yr locked in',
                              style: AppTypography.monoSmall(color: AppColors.signalGreen).copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // FILTER CHIPS BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _ActionFilterChip(
                        label: 'All (${sortedSubs.length})',
                        isSelected: _filter == 'All',
                        onTap: () => setState(() => _filter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _ActionFilterChip(
                        label: 'Cancel Only',
                        isSelected: _filter == 'Cancel',
                        onTap: () => setState(() => _filter = 'Cancel'),
                      ),
                      const SizedBox(width: 8),
                      _ActionFilterChip(
                        label: 'Downgrade Only',
                        isSelected: _filter == 'Downgrade',
                        onTap: () => setState(() => _filter = 'Downgrade'),
                      ),
                    ],
                  ),

                  if (_completedActionIds.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onPressed: () => setState(() => _completedActionIds.clear()),
                      icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.slate),
                      label: Text(
                        'Reset Progress',
                        style: AppTypography.monoSmall(color: AppColors.slate),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // FLEXIBLE 2-COLUMN VIEW (NO BOTTOM STICKY FOOTER, INDEPENDENT SCROLLING LIST)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isNarrow = constraints.maxWidth < 840;

                    Widget actionList = ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filteredSubs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final sub = filteredSubs[index];
                        final isActionable = sub.recommendedAction != 'Keep';
                        final isCompleted = _completedActionIds.contains(sub.id);
                        final annualSaving = sub.monthlySaving * 12;

                        Color actionBadgeColor;
                        if (sub.recommendedAction == 'Cancel') {
                          actionBadgeColor = AppColors.coral;
                        } else if (sub.recommendedAction == 'Downgrade') {
                          actionBadgeColor = AppColors.amber;
                        } else if (sub.recommendedAction == 'Renegotiate') {
                          actionBadgeColor = const Color(0xFF1E88E5);
                        } else {
                          actionBadgeColor = AppColors.signalGreen;
                        }

                        return CardContainer(
                          padding: const EdgeInsets.all(18),
                          backgroundColor: isCompleted ? AppColors.paperDim : AppColors.paper,
                          borderColor: isCompleted ? AppColors.line : (isActionable ? actionBadgeColor.withValues(alpha: 0.4) : AppColors.line),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isActionable)
                                    Transform.scale(
                                      scale: 1.1,
                                      child: Checkbox(
                                        value: isCompleted,
                                        activeColor: AppColors.signalGreen,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _completedActionIds.add(sub.id);
                                            } else {
                                              _completedActionIds.remove(sub.id);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: actionBadgeColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                sub.recommendedAction.toUpperCase(),
                                                style: AppTypography.eyebrow(color: actionBadgeColor).copyWith(fontSize: 10),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              sub.merchant,
                                              style: AppTypography.titleLarge(color: isCompleted ? AppColors.slate : AppColors.ink)
                                                  .copyWith(
                                                      fontSize: 16,
                                                      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.paperDim,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${(sub.confidence * 100).round()}% Confidence',
                                                style: AppTypography.monoSmall(color: AppColors.slate).copyWith(fontSize: 10),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sub.actionReason,
                                                style: AppTypography.bodySmall(color: AppColors.slate),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isActionable) ...[
                                        MoneyText(
                                          amount: annualSaving,
                                          size: MoneySize.small,
                                          color: isCompleted ? AppColors.slate : AppColors.signalGreen,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Save / year',
                                          style: AppTypography.monoSmall(color: AppColors.slate).copyWith(fontSize: 10),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Optimized',
                                          style: AppTypography.monoSmall(color: AppColors.signalGreen),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(color: AppColors.line, height: 1),
                              const SizedBox(height: 10),

                              Align(
                                alignment: Alignment.centerRight,
                                child: Builder(
                                  builder: (context) {
                                    final isAlert = sub.recommendedAction != 'Keep';
                                    return TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        backgroundColor: isAlert ? AppColors.coral.withValues(alpha: 0.12) : AppColors.paperDim,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(
                                            color: isAlert ? AppColors.coral : AppColors.line,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => CancellationGuideModal.show(context, sub.merchant),
                                      icon: Icon(
                                        isAlert ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                        size: 14,
                                        color: isAlert ? AppColors.coral : AppColors.slate,
                                      ),
                                      label: Text(
                                        isAlert
                                            ? 'How to ${sub.recommendedAction} ${sub.merchant} (Action Recommended)'
                                            : 'Cancellation Steps & Link',
                                        style: AppTypography.labelBold(
                                          color: isAlert ? AppColors.coral : AppColors.slate,
                                        ).copyWith(fontSize: 11),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    Widget rightSidebar = Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'POTENTIAL ANNUAL SAVINGS',
                            style: AppTypography.eyebrow(color: AppColors.paper.withValues(alpha: 0.6)).copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 6),
                          MoneyText(
                            amount: totalAnnualSavings,
                            size: MoneySize.large,
                            color: AppColors.paper,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recoverable by executing identified plan changes',
                            style: AppTypography.bodySmall(color: AppColors.paper.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: AppColors.paper.withValues(alpha: 0.12), height: 1),
                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MONTHLY IMPACT',
                                    style: AppTypography.eyebrow(color: AppColors.paper.withValues(alpha: 0.6)).copyWith(fontSize: 9),
                                  ),
                                  const SizedBox(height: 4),
                                  MoneyText(
                                    amount: totalAnnualSavings / 12,
                                    size: MoneySize.medium,
                                    color: AppColors.signalGreen,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'RECOVERY RATE',
                                    style: AppTypography.eyebrow(color: AppColors.paper.withValues(alpha: 0.6)).copyWith(fontSize: 9),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${actionableSubs.isNotEmpty ? ((_completedActionIds.length / actionableSubs.length) * 100).toStringAsFixed(0) : 100}%',
                                    style: AppTypography.labelBold(color: AppColors.paper).copyWith(fontSize: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.signalGreen,
                                foregroundColor: AppColors.paper,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _copyActionPlanToClipboard(context, sortedSubs, totalAnnualSavings),
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: Text(
                                'Export Action Plan',
                                style: AppTypography.labelBold(color: AppColors.paper).copyWith(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            actionList,
                            const SizedBox(height: 24),
                            rightSidebar,
                          ],
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: actionList),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: rightSidebar),
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

class _ActionFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionFilterChip({
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
