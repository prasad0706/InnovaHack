import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'money_text.dart';

class TransactionLedgerModal extends StatefulWidget {
  const TransactionLedgerModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionLedgerModal(),
    );
  }

  @override
  State<TransactionLedgerModal> createState() => _TransactionLedgerModalState();
}

class _TransactionLedgerModalState extends State<TransactionLedgerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    
    // Strict client-side deduplication
    final Set<String> seenKeys = {};
    final List<TransactionRecord> uniqueTxns = [];

    for (final t in provider.allTransactions) {
      final mKey = (t.merchant.isNotEmpty ? t.merchant : t.rawDescription).toLowerCase().trim();
      final dedupKey = '${t.date}_${t.amount.toStringAsFixed(2)}_$mKey';
      if (!seenKeys.contains(dedupKey)) {
        seenKeys.add(dedupKey);
        uniqueTxns.add(t);
      }
    }

    final filtered = uniqueTxns.where((t) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return t.merchant.toLowerCase().contains(q) ||
          t.rawDescription.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.date.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: AppColors.ink, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statement Transaction Ledger',
                              style: AppTypography.headlineMedium(color: AppColors.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${uniqueTxns.length} Unique Entries · Sorted Chronologically',
                              style: AppTypography.bodySmall(color: AppColors.slate),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.slate),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _filter = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Filter by merchant, category, or date...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate),
                    suffixIcon: _filter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _filter = '';
                              });
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
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppColors.slate),
                        const SizedBox(height: 12),
                        Text(
                          'No matching transaction entries found',
                          style: AppTypography.labelBold(color: AppColors.slate),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(color: AppColors.line, height: 1),
                    itemBuilder: (context, index) {
                      final item = filtered[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.paperDim,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.merchant.isNotEmpty ? item.merchant : item.rawDescription,
                                        style: AppTypography.labelBold(color: AppColors.ink),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.paperDim,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.category,
                                          style: AppTypography.monoSmall(color: AppColors.slate).copyWith(fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.rawDescription,
                                    style: AppTypography.bodySmall(color: AppColors.slate),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                MoneyText(
                                  amount: item.amount,
                                  size: MoneySize.small,
                                  color: AppColors.ink,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.formattedDate,
                                  style: AppTypography.monoSmall(color: AppColors.slate),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
