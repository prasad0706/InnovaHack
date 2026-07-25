import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'money_text.dart';

class UserProfileModal extends StatefulWidget {
  const UserProfileModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UserProfileModal(),
    );
  }

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal> {
  late TextEditingController _goalController;
  late TextEditingController _nameController;

  final List<double> _presetGoals = [1000, 2000, 3000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AnalysisProvider>(context, listen: false);
    _goalController = TextEditingController(text: provider.monthlySavingsGoal.toStringAsFixed(0));
    _nameController = TextEditingController(text: provider.userName);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _saveTarget() {
    final provider = Provider.of<AnalysisProvider>(context, listen: false);
    double? goal = double.tryParse(_goalController.text.trim());

    provider.updateUserProfile(
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : provider.userName,
      goal: goal != null && goal > 0 ? goal : 3000.0,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Monthly Savings Target updated to ₹${(goal ?? 3000).toStringAsFixed(0)}!', style: AppTypography.bodyMedium(color: AppColors.paper)),
        backgroundColor: AppColors.signalGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final currentLeakage = provider.potentialMonthlySavings;

    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.signalGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.track_changes_rounded, color: AppColors.signalGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Monthly Savings Target',
                      style: AppTypography.headlineMedium(color: AppColors.ink).copyWith(fontSize: 18),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.slate),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Set your target monthly recovery goal to track progress on your Health Score dashboard.',
              style: AppTypography.bodySmall(color: AppColors.slate),
            ),
            const SizedBox(height: 20),

            // DETECTED POTENTIAL SAVINGS BANNER
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paperDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATEMENT RECOVERY POTENTIAL',
                        style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 9),
                      ),
                      const SizedBox(height: 2),
                      MoneyText(
                        amount: currentLeakage,
                        size: MoneySize.small,
                        color: AppColors.signalGreen,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.signalGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Available Leaks',
                      style: AppTypography.monoSmall(color: AppColors.signalGreen).copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'TARGET MONTHLY SAVINGS (₹)',
              style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              style: AppTypography.headlineMedium(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: '3000',
                prefixText: '₹ ',
                prefixStyle: AppTypography.headlineMedium(color: AppColors.ink),
                filled: true,
                fillColor: AppColors.paperDim,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // PRESET TARGET PILLS
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetGoals.map((g) {
                final isSelected = double.tryParse(_goalController.text) == g;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _goalController.text = g.toStringAsFixed(0);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.ink : AppColors.paperDim,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.ink : AppColors.line),
                    ),
                    child: Text(
                      '₹${g.toStringAsFixed(0)}',
                      style: AppTypography.labelBold(
                        color: isSelected ? AppColors.paper : AppColors.ink,
                      ).copyWith(fontSize: 11),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.paper,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saveTarget,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text('Update Savings Target', style: AppTypography.labelBold(color: AppColors.paper)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
