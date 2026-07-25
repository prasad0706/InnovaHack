import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/subscription_model.dart';
import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/card_container.dart';
import '../widgets/money_text.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  SubscriptionItem? _selectedNegotiationSub;

  void _copyNegotiationLetter(BuildContext context, SubscriptionItem sub) {
    final letter = '''
Subject: Request for Retention Discount / Plan Price Reduction for ${sub.merchant}

Dear ${sub.merchant} Customer Support,

I have been a valued subscriber to ${sub.merchant} (Current Plan: ₹${sub.currentAmount.toStringAsFixed(0)}/mo). However, after reviewing my monthly recurring software expenses, I am evaluating my active subscriptions.

Before considering plan cancellation, I would like to inquire if there are any available loyalty discounts, retention offers, or lower-tier plans that could reduce my monthly cost.

Please let me know the available options to adjust my plan rate.

Thank you for your assistance.

Sincerely,
SubSense User
''';

    Clipboard.setData(ClipboardData(text: letter));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.signalGreen, size: 18),
            const SizedBox(width: 10),
            Text(
              'Negotiation letter for ${sub.merchant} copied to clipboard!',
              style: AppTypography.bodyMedium(color: AppColors.paper),
            ),
          ],
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyCalendarReminders(BuildContext context, List<SubscriptionItem> subs) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("=== SUBSENSE RECURRING RENEWAL CALENDAR ALERTS ===");
    for (final s in subs) {
      buffer.writeln("• ${s.merchant}: Next Renewal ${s.formattedNextRenewalDate} (Amount: ₹${s.currentAmount.toStringAsFixed(0)})");
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.signalGreen, size: 18),
            const SizedBox(width: 10),
            Text(
              'Renewal reminders copied to clipboard for Calendar import!',
              style: AppTypography.bodyMedium(color: AppColors.paper),
            ),
          ],
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final subs = provider.subscriptions;

    double totalMonthly = subs.fold(0.0, (sum, s) => sum + s.currentAmount);
    int hikeCount = provider.priceIncreaseCount;
    double potentialMonthlySave = provider.potentialMonthlySavings;
    double potentialAnnualSave = potentialMonthlySave * 12;

    _selectedNegotiationSub ??= subs.isNotEmpty ? subs.first : null;

    List<Map<String, String>> insights = [
      {
        'title': 'Active Recurring Spend Portfolio',
        'body': 'You spend ₹${totalMonthly.toStringAsFixed(0)} monthly across ${subs.length} active recurring subscriptions.',
        'tag': '${subs.length} Active Services',
      },
    ];

    if (hikeCount > 0) {
      insights.add({
        'title': 'Silent Price Hike Leak Detected',
        'body': 'Silent price hikes were detected on $hikeCount subscription${hikeCount > 1 ? 's' : ''}. Switching or downgrading plans can recover ₹${provider.monthlyLeakage.toStringAsFixed(0)} monthly.',
        'tag': '+$hikeCount Hikes Flagged',
      });
    }

    if (potentialMonthlySave > 0) {
      insights.add({
        'title': 'Annual Recovery Potential',
        'body': 'Plugging identified leaks will unlock ₹${potentialMonthlySave.toStringAsFixed(0)} in monthly savings, returning ₹${potentialAnnualSave.toStringAsFixed(0)} back to your annual budget.',
        'tag': '₹${potentialAnnualSave.toStringAsFixed(0)}/yr Recoverable',
      });
    } else {
      insights.add({
        'title': 'Optimized Subscription Status',
        'body': 'Your subscription portfolio is well-optimized with zero active price hikes or duplicate services detected.',
        'tag': 'Optimized Portfolio',
      });
    }

    insights.add({
      'title': 'Quarterly Subscription Hygiene',
      'body': 'Reviewing recurring subscriptions quarterly prevents forgotten auto-debits from quietly draining cash reserves.',
      'tag': 'Best Practice',
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.signalGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.signalGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ACTIONABLE ADVISOR',
                                    style: AppTypography.eyebrow(color: AppColors.signalGreen).copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Financial Intelligence & Action Tools',
                          style: AppTypography.headlineMedium(color: AppColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Derived recommendations, price negotiation letters, and auto-debit renewal alerts for your subscriptions.',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ANNUAL POTENTIAL',
                          style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 9),
                        ),
                        const SizedBox(height: 2),
                        MoneyText(
                          amount: potentialAnnualSave,
                          size: MoneySize.small,
                          color: AppColors.signalGreen,
                        ),
                        Text(
                          'Recoverable Savings',
                          style: AppTypography.monoSmall(color: AppColors.slate).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // FLEXIBLE 2-COLUMN VIEW
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isNarrow = constraints.maxWidth < 840;

                    Widget insightsList = ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: insights.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = insights[index];

                        return CardContainer(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.signalGreen.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.insights_rounded, color: AppColors.signalGreen, size: 18),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['title']!,
                                          style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.paperDim,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.line),
                                          ),
                                          child: Text(
                                            item['tag']!,
                                            style: AppTypography.monoSmall(color: AppColors.ink).copyWith(fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['body']!,
                                      style: AppTypography.bodySmall(color: AppColors.slate).copyWith(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    Widget actionToolsWidget = ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        // TOOL 1: NEGOTIATION DRAFT GENERATOR
                        CardContainer(
                          padding: const EdgeInsets.all(20),
                          backgroundColor: AppColors.paperDim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.note_alt_outlined, color: AppColors.ink, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '1-Click Price Negotiation Letter',
                                    style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Generate a formal retention discount request to lower monthly rates.',
                                style: AppTypography.bodySmall(color: AppColors.slate),
                              ),
                              const SizedBox(height: 14),

                              if (subs.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.paper,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<SubscriptionItem>(
                                      value: _selectedNegotiationSub,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.ink),
                                      items: subs.map((s) {
                                        return DropdownMenuItem<SubscriptionItem>(
                                          value: s,
                                          child: Text(
                                            '${s.merchant} (₹${s.currentAmount.toStringAsFixed(0)}/mo)',
                                            style: AppTypography.labelBold(color: AppColors.ink).copyWith(fontSize: 13),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedNegotiationSub = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.ink,
                                      foregroundColor: AppColors.paper,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      if (_selectedNegotiationSub != null) {
                                        _copyNegotiationLetter(context, _selectedNegotiationSub!);
                                      }
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                    label: Text(
                                      'Copy Negotiation Letter Draft',
                                      style: AppTypography.labelBold(color: AppColors.paper).copyWith(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // TOOL 2: CALENDAR RENEWAL REMINDERS
                        CardContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: AppColors.ink, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Renewal Alert Exporter',
                                    style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Export upcoming renewal dates to Google Calendar or iCal.',
                                style: AppTypography.bodySmall(color: AppColors.slate),
                              ),
                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: AppColors.line),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _copyCalendarReminders(context, subs),
                                  icon: const Icon(Icons.event_note_rounded, size: 16, color: AppColors.ink),
                                  label: Text(
                                    'Export All Renewal Dates (${subs.length} Services)',
                                    style: AppTypography.labelBold(color: AppColors.ink).copyWith(fontSize: 13),
                                  ),
                                ),
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
                            insightsList,
                            const SizedBox(height: 24),
                            actionToolsWidget,
                          ],
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: insightsList),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: actionToolsWidget),
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
