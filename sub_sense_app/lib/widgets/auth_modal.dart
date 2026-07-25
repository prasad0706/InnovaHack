import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AuthModal extends StatefulWidget {
  const AuthModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AuthModal(),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  bool _isRegistering = false;

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();

  bool _obscureLoginPw = true;
  bool _obscureRegPw = true;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);

    final success = await authProvider.login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (success && mounted) {
      analysisProvider.updateUserProfile(name: authProvider.userName);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${authProvider.userName}!', style: AppTypography.bodyMedium(color: AppColors.paper)),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);

    final success = await authProvider.register(
      _regEmailController.text.trim(),
      _regPasswordController.text,
      _regNameController.text.trim(),
    );

    if (success && mounted) {
      analysisProvider.updateUserProfile(name: authProvider.userName);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully! Welcome, ${authProvider.userName}.', style: AppTypography.bodyMedium(color: AppColors.paper)),
          backgroundColor: AppColors.signalGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
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
                      const Icon(Icons.shield_outlined, color: AppColors.ink, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'SubSense Auth',
                        style: AppTypography.headlineMedium(color: AppColors.ink),
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

              // Segmented Tab Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.paperDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isRegistering = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isRegistering ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign In',
                            style: AppTypography.labelBold(
                              color: !_isRegistering ? AppColors.paper : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isRegistering = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isRegistering ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Create Account',
                            style: AppTypography.labelBold(
                              color: _isRegistering ? AppColors.paper : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (authProvider.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.coral),
                  ),
                  child: Text(
                    authProvider.errorMessage!,
                    style: AppTypography.bodySmall(color: AppColors.coral),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!_isRegistering) ...[
                // Sign In Form
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EMAIL ADDRESS', style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _loginEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'name@domain.com',
                        hintStyle: AppTypography.bodyMedium(color: AppColors.slate.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.paperDim,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('PASSWORD', style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _loginPasswordController,
                      obscureText: _obscureLoginPw,
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        hintStyle: AppTypography.bodyMedium(color: AppColors.slate.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.paperDim,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureLoginPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.slate),
                          onPressed: () => setState(() => _obscureLoginPw = !_obscureLoginPw),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.paper,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        child: authProvider.isLoading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: AppColors.paper, strokeWidth: 2))
                            : Text('Sign In', style: AppTypography.labelBold(color: AppColors.paper)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Register Form
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FULL NAME', style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _regNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Vedant Sharma',
                        hintStyle: AppTypography.bodyMedium(color: AppColors.slate.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.paperDim,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('EMAIL ADDRESS', style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _regEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'name@domain.com',
                        hintStyle: AppTypography.bodyMedium(color: AppColors.slate.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.paperDim,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('PASSWORD (MIN 6 CHARS)', style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _regPasswordController,
                      obscureText: _obscureRegPw,
                      decoration: InputDecoration(
                        hintText: 'Create password',
                        hintStyle: AppTypography.bodyMedium(color: AppColors.slate.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.paperDim,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureRegPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.slate),
                          onPressed: () => setState(() => _obscureRegPw = !_obscureRegPw),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.signalGreen,
                          foregroundColor: AppColors.paper,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: authProvider.isLoading ? null : _handleRegister,
                        child: authProvider.isLoading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: AppColors.paper, strokeWidth: 2))
                            : Text('Register Account', style: AppTypography.labelBold(color: AppColors.paper)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
