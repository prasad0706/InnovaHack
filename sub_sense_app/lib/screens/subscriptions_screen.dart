import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subscription_model.dart';
import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/badge_tag.dart';
import '../widgets/card_container.dart';
import '../widgets/money_text.dart';
import '../widgets/payment_history_chart.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final subs = provider.subscriptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUBSCRIPTIONS',
                style: AppTypography.eyebrow(color: AppColors.signalGreen),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detected Subscriptions',
                    style: AppTypography.headlineLarge(color: AppColors.ink),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paperDim,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      '${subs.length} Active',
                      style: AppTypography.monoRegular(color: AppColors.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Expand any subscription card to view historical payment trends and tailored optimization guidance.',
                style: AppTypography.bodyLarge(color: AppColors.slate),
              ),
              const SizedBox(height: 32),

              // Expandable Subscription Cards List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return SubscriptionCard(item: subs[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubscriptionCard extends StatefulWidget {
  final SubscriptionItem item;

  const SubscriptionCard({super.key, required this.item});

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final sub = widget.item;
    final hasHike = sub.priceChange?.increased == true;
    final isDuplicate = sub.category == 'Duplicate';

    return CardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Collapsed Header Row
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Merchant Avatar Initial
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.paperDim,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      sub.merchant.isNotEmpty ? sub.merchant[0] : 'S',
                      style: AppTypography.headlineMedium(color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Merchant Name & Tags
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sub.merchant,
                                style: AppTypography.titleLarge(
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasHike) ...[
                              const SizedBox(width: 8),
                              BadgeTag.priceHike(
                                '+${sub.priceChange!.percentChange}%',
                              ),
                            ],
                            if (isDuplicate) ...[
                              const SizedBox(width: 8),
                              BadgeTag.duplicate('Duplicate'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sub.category} · ${sub.frequency}',
                          style: AppTypography.bodySmall(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount & Chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MoneyText(
                        amount: sub.current_amount,
                        size: MoneySize.medium,
                        color: AppColors.ink,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'per ${sub.frequency == "monthly" ? "mo" : "yr"}',
                            style: AppTypography.bodySmall(
                              color: AppColors.slate,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.slate,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details Panel
          if (_isExpanded) ...[
            const Divider(color: AppColors.line, height: 1),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stacked Panel 1: Payment History Bar Chart
                  PaymentHistoryChart(
                    history: sub.history,
                    hasPriceHike: hasHike,
                  ),
                  const SizedBox(height: 24),

                  // Stacked Panel 2: Recommendation Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.signalGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.signalGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _getRecommendationBadge(sub.recommendedAction),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECOMMENDED ACTION: ${sub.recommendedAction.toUpperCase()}',
                                style: AppTypography.eyebrow(
                                  color: AppColors.signalGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sub.actionReason,
                                style: AppTypography.bodyMedium(
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sub.monthlySaving > 0) ...[
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'POTENTIAL SAVING',
                                style: AppTypography.eyebrow(
                                  color: AppColors.slate,
                                ).copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 2),
                              MoneyText(
                                amount: sub.monthlySaving,
                                size: MoneySize.small,
                                color: AppColors.signalGreen,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getRecommendationBadge(String action) {
    switch (action) {
      case 'Cancel':
        return BadgeTag.cancel('Cancel');
      case 'Downgrade':
        return BadgeTag.downgrade('Downgrade');
      default:
        return BadgeTag.keep('Keep');
    }
  }
}
