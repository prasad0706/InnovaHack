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
import '../widgets/cancellation_guide_modal.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final subs = provider.subscriptions;

    // Categories list
    final categories = ['All', ...subs.map((s) => s.category).toSet()];

    // Filtered subscriptions
    final filteredSubs = subs.where((s) {
      final matchesCategory = _selectedCategory == 'All' || s.category == _selectedCategory;
      final matchesSearch = _searchFilter.isEmpty ||
          s.merchant.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          s.category.toLowerCase().contains(_searchFilter.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    // Upcoming Auto Debits sorted by urgency
    List<SubscriptionItem> upcomingSubs = List.from(subs);
    upcomingSubs.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

    final totalMonthlySpend = subs.fold(0.0, (sum, s) => sum + s.currentAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PRIMARY TOP HERO HEADER (DETAILED SUBSCRIPTIONS CENTER STAGE)
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
                              child: Text(
                                'ACTIVE SUBSCRIPTION MANAGEMENT',
                                style: AppTypography.eyebrow(color: AppColors.signalGreen).copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Detected Subscriptions',
                          style: AppTypography.headlineLarge(color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Comprehensive breakdown of all recurring plans, silent price hikes, and upcoming renewals.',
                          style: AppTypography.bodyMedium(color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.paperDim,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL RECURRING SPEND',
                          style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 9),
                        ),
                        const SizedBox(height: 4),
                        MoneyText(
                          amount: totalMonthlySpend,
                          size: MoneySize.medium,
                          color: AppColors.ink,
                        ),
                        Text(
                          '${subs.length} Active Services',
                          style: AppTypography.monoSmall(color: AppColors.slate).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // SEARCH & CATEGORY FILTER BAR
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchFilter = val),
                      decoration: InputDecoration(
                        hintText: 'Search subscriptions by merchant or category...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate),
                        suffixIcon: _searchFilter.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchFilter = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.paperDim,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.ink,
                        backgroundColor: AppColors.paperDim,
                        checkmarkColor: AppColors.paper,
                        labelStyle: AppTypography.labelBold(
                          color: isSelected ? AppColors.paper : AppColors.ink,
                        ).copyWith(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? AppColors.ink : AppColors.line),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // MAIN CONTENT RESPONSIVE GRID
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isNarrow = constraints.maxWidth < 840;

                  Widget subscriptionsList = filteredSubs.isEmpty
                      ? CardContainer(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.search_off_rounded, size: 40, color: AppColors.slate),
                                const SizedBox(height: 12),
                                Text(
                                  'No matching subscriptions found',
                                  style: AppTypography.labelBold(color: AppColors.slate),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredSubs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return SubscriptionCard(item: filteredSubs[index]);
                          },
                        );

                  Widget rightSidebar = Column(
                    children: [
                      // COMPACT SIDEBAR: UPCOMING AUTO-DEBITS TICKER
                      CardContainer(
                        padding: const EdgeInsets.all(20),
                        backgroundColor: AppColors.paperDim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, color: AppColors.ink, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Upcoming Renewals',
                                      style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${upcomingSubs.length} Next Up',
                                    style: AppTypography.monoSmall(color: AppColors.amber).copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: upcomingSubs.take(4).length,
                              separatorBuilder: (context, index) => const Divider(color: AppColors.line, height: 16),
                              itemBuilder: (context, index) {
                                final item = upcomingSubs[index];
                                final isUrgent = item.daysRemaining <= 7;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.merchant,
                                            style: AppTypography.labelBold(color: AppColors.ink).copyWith(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.formattedNextRenewalDate,
                                            style: AppTypography.bodySmall(color: AppColors.slate).copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isUrgent ? AppColors.amber.withValues(alpha: 0.15) : AppColors.paper,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: isUrgent ? AppColors.amber : AppColors.line),
                                          ),
                                          child: Text(
                                            item.remainingTimeText,
                                            style: AppTypography.monoSmall(
                                              color: isUrgent ? AppColors.amber : AppColors.ink,
                                            ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        MoneyText(
                                          amount: item.currentAmount,
                                          size: MoneySize.small,
                                          color: AppColors.ink,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // COMPACT SIDEBAR: CATEGORY BREAKDOWN
                      CardContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category Breakdown',
                              style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 16),

                            ..._buildCategoryBars(subs, totalMonthlySpend),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        subscriptionsList,
                        const SizedBox(height: 32),
                        rightSidebar,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: subscriptionsList),
                      const SizedBox(width: 28),
                      Expanded(flex: 2, child: rightSidebar),
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

  List<Widget> _buildCategoryBars(List<SubscriptionItem> subs, double totalSpend) {
    if (totalSpend == 0) return [];

    final Map<String, double> categorySpend = {};
    for (final s in subs) {
      categorySpend[s.category] = (categorySpend[s.category] ?? 0) + s.currentAmount;
    }

    final entries = categorySpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((entry) {
      final ratio = entry.value / totalSpend;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: AppTypography.bodySmall(color: AppColors.ink).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '₹${entry.value.toStringAsFixed(0)} (${(ratio * 100).toStringAsFixed(0)}%)',
                  style: AppTypography.monoSmall(color: AppColors.slate).copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColors.paperDim,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
              ),
            ),
          ],
        ),
      );
    }).toList();
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
                          '${sub.category} · Next: ${sub.formattedNextRenewalDate} (${sub.remainingTimeText})',
                          style: AppTypography.bodySmall(color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MoneyText(
                        amount: sub.currentAmount,
                        size: MoneySize.medium,
                        color: AppColors.ink,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'per ${sub.frequency == "monthly" ? "mo" : "yr"}',
                            style: AppTypography.bodySmall(color: AppColors.slate),
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

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(color: AppColors.line, height: 1),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PaymentHistoryChart(
                        history: sub.history,
                        hasPriceHike: hasHike,
                      ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.signalGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.signalGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
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
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
