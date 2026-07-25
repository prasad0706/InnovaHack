import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PlaidBankModal extends StatefulWidget {
  const PlaidBankModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PlaidBankModal(),
    );
  }

  @override
  State<PlaidBankModal> createState() => _PlaidBankModalState();
}

class _PlaidBankModalState extends State<PlaidBankModal> {
  int _step = 1; // 1: Bank Selection, 2: Consent, 3: Bank PIN Auth, 4: Processing
  String _selectedBank = 'HDFC';
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  String? _pinError;

  String _progressText = 'Connecting to Bank API...';
  double _progressValue = 0.2;

  final List<Map<String, dynamic>> _banks = [
    {'name': 'HDFC', 'logo': Icons.account_balance_rounded, 'color': const Color(0xFF004C8F)},
    {'name': 'ICICI', 'logo': Icons.account_balance_wallet_rounded, 'color': const Color(0xFFB02A30)},
    {'name': 'State Bank of India', 'logo': Icons.domain_rounded, 'color': const Color(0xFF1C63B7)},
    {'name': 'Axis', 'logo': Icons.monetization_on_rounded, 'color': const Color(0xFF97144D)},
    {'name': 'Bank of Baroda', 'logo': Icons.business_rounded, 'color': const Color(0xFF1175C4)},
    {'name': 'HSBC', 'logo': Icons.savings_rounded, 'color': const Color(0xFFD41129)},
  ];

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPinAndConnect() {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _pinError = 'Please enter a 4-digit bank PIN (e.g. 1234)';
      });
      return;
    }

    setState(() {
      _pinError = null;
    });

    _startBankConnection();
  }

  Future<void> _startBankConnection() async {
    setState(() {
      _step = 4;
      _progressText = 'Verifying Bank PIN & Connecting to $_selectedBank Sandbox...';
      _progressValue = 0.25;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _progressText = 'Fetching 6 Months Transaction History...';
      _progressValue = 0.55;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);

      final result = await ApiService.connectBankAccount(
        bankName: _selectedBank,
        token: authProvider.token,
      );

      if (!mounted) return;
      setState(() {
        _progressText = 'Running Recurring Detection & Price Hike Pipeline...';
        _progressValue = 0.85;
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      setState(() {
        _progressText = 'Persisting Analysis & Health Score to Database...';
        _progressValue = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      analysisProvider.updateUserProfile(label: '$_selectedBank Account');
      analysisProvider.setAnalysisResult(result);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to $_selectedBank! Analysis loaded directly from database.', style: AppTypography.bodyMedium(color: AppColors.paper)),
          backgroundColor: AppColors.signalGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect bank: $e', style: AppTypography.bodyMedium(color: AppColors.paper)),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
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
                    const Icon(Icons.shield_rounded, color: AppColors.ink, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Connect Bank Account',
                      style: AppTypography.headlineMedium(color: AppColors.ink),
                    ),
                  ],
                ),
                if (_step != 4)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.signalGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PLAID SANDBOX MODE',
                    style: AppTypography.monoSmall(color: AppColors.signalGreen).copyWith(fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Security Step ${_step > 3 ? 3 : _step} of 3',
                  style: AppTypography.bodySmall(color: AppColors.slate),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_step == 1) ...[
              Text(
                'SELECT YOUR BANK',
                style: AppTypography.eyebrow(color: AppColors.slate).copyWith(fontSize: 10),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _banks.length,
                itemBuilder: (context, index) {
                  final bank = _banks[index];
                  final isSelected = _selectedBank == bank['name'];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedBank = bank['name']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? (bank['color'] as Color).withValues(alpha: 0.1) : AppColors.paperDim,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? bank['color'] as Color : AppColors.line,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: bank['color'] as Color,
                            child: Icon(bank['logo'] as IconData, size: 14, color: AppColors.paper),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bank['name'] as String,
                              style: AppTypography.labelBold(
                                color: isSelected ? bank['color'] as Color : AppColors.ink,
                              ).copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => setState(() => _step = 2),
                  child: Text('Continue with $_selectedBank', style: AppTypography.labelBold(color: AppColors.paper)),
                ),
              ),
            ] else if (_step == 2) ...[
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
                      children: [
                        const Icon(Icons.shield_rounded, color: AppColors.signalGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Read-Only Access Consent',
                          style: AppTypography.labelBold(color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SubSense uses Plaid Sandbox to securely connect to $_selectedBank. By proceeding, you authorize SubSense to fetch transaction history for recurring payment leak detection.',
                      style: AppTypography.bodySmall(color: AppColors.slate),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '🔒 End-to-end encrypted · Read-Only Access · Zero credentials stored.',
                      style: AppTypography.monoSmall(color: AppColors.signalGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setState(() => _step = 1),
                      child: Text('Back', style: AppTypography.labelBold(color: AppColors.slate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.paper,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setState(() => _step = 3),
                      child: Text('Next: Enter Bank PIN', style: AppTypography.labelBold(color: AppColors.paper)),
                    ),
                  ),
                ],
              ),
            ] else if (_step == 3) ...[
              // STEP 3: DUMMY BANK PIN AUTHENTICATION
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paperDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_person_rounded, color: AppColors.ink, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          '$_selectedBank NetBanking Security PIN',
                          style: AppTypography.labelBold(color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your 4-digit Bank PIN or Passcode to authenticate connection.',
                      style: AppTypography.bodySmall(color: AppColors.slate),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _pinController,
                      obscureText: _obscurePin,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: AppTypography.headlineMedium(color: AppColors.ink),
                      decoration: InputDecoration(
                        labelText: '4-Digit Bank PIN',
                        hintText: '••••',
                        errorText: _pinError,
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.paper,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.slate,
                          ),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                      ),
                      onSubmitted: (_) => _verifyPinAndConnect(),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.signalGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.signalGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sandbox Demo Mode: Enter any 4-digit PIN (e.g. 1234)',
                              style: AppTypography.monoSmall(color: AppColors.signalGreen).copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setState(() => _step = 2),
                      child: Text('Back', style: AppTypography.labelBold(color: AppColors.slate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.signalGreen,
                        foregroundColor: AppColors.paper,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _verifyPinAndConnect,
                      child: Text('Verify PIN & Connect', style: AppTypography.labelBold(color: AppColors.paper)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Column(
                children: [
                  const SizedBox(height: 12),
                  const SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 3),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    _progressText,
                    style: AppTypography.labelBold(color: AppColors.ink),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressValue,
                      minHeight: 8,
                      backgroundColor: AppColors.line,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.signalGreen),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Automated analysis in progress... Please do not close.',
                    style: AppTypography.bodySmall(color: AppColors.slate),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
