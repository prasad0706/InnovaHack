import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'auth_modal.dart';
import 'user_profile_modal.dart';

class NavShell extends StatelessWidget {
  final Widget body;

  const NavShell({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'SubSense',
                        style: AppTypography.headlineMedium(color: AppColors.ink),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LEAK DETECTOR',
                        style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10),
                      ),
                    ],
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.paperDim,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _NavPill(index: 0, label: 'Upload', enabled: true),
                                _NavPill(index: 1, label: 'Health', enabled: provider.isAnalyzed),
                                _NavPill(index: 2, label: 'Subscriptions', enabled: provider.isAnalyzed),
                                _NavPill(index: 3, label: 'Simulator', enabled: provider.isAnalyzed),
                                _NavPill(index: 4, label: 'Actions', enabled: provider.isAnalyzed),
                                _NavPill(index: 5, label: 'AI Coach', enabled: provider.isAnalyzed),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          if (!authProvider.isLoggedIn) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ink,
                                foregroundColor: AppColors.paper,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () => AuthModal.show(context),
                              icon: const Icon(Icons.login_rounded, size: 14),
                              label: Text('Sign In', style: AppTypography.labelBold(color: AppColors.paper)),
                            ),
                          ] else ...[
                            PopupMenuButton<String>(
                              onSelected: (val) async {
                                if (val == 'edit') {
                                  UserProfileModal.show(context);
                                } else if (val == 'disconnect_bank') {
                                  final success = await ApiService.disconnectBankAccount(authProvider.token);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success ? 'Bank account disconnected.' : 'Disconnected local bank status.',
                                          style: AppTypography.bodyMedium(color: AppColors.paper),
                                        ),
                                        backgroundColor: AppColors.ink,
                                      ),
                                    );
                                  }
                                } else if (val == 'logout') {
                                  authProvider.logout();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.tune_rounded, size: 16, color: AppColors.ink),
                                      const SizedBox(width: 10),
                                      Text('Edit Profile & Target', style: AppTypography.bodyMedium(color: AppColors.ink)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'disconnect_bank',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.link_off_rounded, size: 16, color: AppColors.amber),
                                      const SizedBox(width: 10),
                                      Text('Disconnect Bank Account', style: AppTypography.bodyMedium(color: AppColors.amber)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout_rounded, size: 16, color: AppColors.coral),
                                      const SizedBox(width: 10),
                                      Text('Sign Out', style: AppTypography.bodyMedium(color: AppColors.coral)),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.paperDim,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.ink,
                                      child: Text(
                                        authProvider.userInitial,
                                        style: AppTypography.monoSmall(color: AppColors.paper).copyWith(fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      authProvider.userDisplayName,
                                      style: AppTypography.labelBold(color: AppColors.ink),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.slate),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final int index;
  final String label;
  final bool enabled;

  const _NavPill({
    required this.index,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final isSelected = provider.activeTabIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: enabled ? () => provider.setTab(index) : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: AppTypography.labelBold(
              color: isSelected
                  ? AppColors.paper
                  : enabled
                      ? AppColors.ink
                      : AppColors.slate.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
