import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/cancellation_guides.dart';
import '../utils/url_helper.dart';

class CancellationGuideModal extends StatelessWidget {
  final String merchant;

  const CancellationGuideModal({super.key, required this.merchant});

  static void show(BuildContext context, String merchant) {
    showDialog(
      context: context,
      builder: (context) => CancellationGuideModal(merchant: merchant),
    );
  }

  void _openUrl(BuildContext context, String urlStr) {
    try {
      LaunchUrlUtil.open(urlStr);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening $merchant cancellation page in new tab...', style: AppTypography.bodyMedium(color: AppColors.paper)),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      Clipboard.setData(ClipboardData(text: urlStr));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard! Paste in your browser.'),
          backgroundColor: AppColors.ink,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = CancellationGuide.getForMerchant(merchant);

    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
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
                          color: AppColors.coral.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cancel_outlined, color: AppColors.coral, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How to Cancel ${guide.merchant}',
                            style: AppTypography.headlineMedium(color: AppColors.ink).copyWith(fontSize: 18),
                          ),
                          Text(
                            'Official step-by-step guide & cancellation link',
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
              const SizedBox(height: 24),

              // DIRECT LINK BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openUrl(context, guide.directUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    'Open Official ${guide.merchant} Cancellation Page',
                    style: AppTypography.labelBold(color: AppColors.paper).copyWith(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'STEP-BY-STEP CANCELLATION GUIDE',
                style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: guide.steps.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.paperDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.ink,
                          child: Text(
                            '${index + 1}',
                            style: AppTypography.monoSmall(color: AppColors.paper).copyWith(fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            guide.steps[index],
                            style: AppTypography.bodySmall(color: AppColors.ink).copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // PRE-WRITTEN EMAIL DRAFT
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paperDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, color: AppColors.ink, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Support Email Template',
                              style: AppTypography.labelBold(color: AppColors.ink),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: guide.emailTemplate));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied email template for ${guide.merchant}!', style: AppTypography.bodyMedium(color: AppColors.paper)),
                                backgroundColor: AppColors.signalGreen,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.signalGreen),
                          label: Text(
                            'Copy Draft',
                            style: AppTypography.monoSmall(color: AppColors.signalGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        guide.emailTemplate,
                        style: AppTypography.monoSmall(color: AppColors.ink).copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
