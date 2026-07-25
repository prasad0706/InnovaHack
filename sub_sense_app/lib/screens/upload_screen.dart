import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/plaid_bank_modal.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  int? _selectedFileSize;

  bool _needsPassword = false;
  bool _isWrongPassword = false;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final provider = Provider.of<AnalysisProvider>(context, listen: false);
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileSize = result.files.single.size;
          _needsPassword = false;
          _isWrongPassword = false;
        });
      }
    } catch (e) {
      provider.setError('Could not open file picker. Please try again.');
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFileName = null;
      _selectedFileBytes = null;
      _selectedFileSize = null;
      _needsPassword = false;
      _isWrongPassword = false;
      _passwordController.clear();
    });
    Provider.of<AnalysisProvider>(context, listen: false).setLoading(false);
  }

  Future<void> _analyzeStatement({String? password}) async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;

    final provider = Provider.of<AnalysisProvider>(context, listen: false);
    provider.setLoading(true);

    try {
      final result = await ApiService.uploadStatement(
        fileBytes: _selectedFileBytes!,
        filename: _selectedFileName!,
        password: password,
      );

      provider.setAnalysisResult(result);
    } on ApiException catch (e) {
      provider.setLoading(false);
      if (e.code == 'PDF_PASSWORD_REQUIRED') {
        setState(() {
          _needsPassword = true;
          _isWrongPassword = false;
        });
      } else if (e.code == 'PDF_PASSWORD_INCORRECT') {
        setState(() {
          _needsPassword = true;
          _isWrongPassword = true;
        });
      } else {
        provider.setError(e.message);
      }
    } catch (e) {
      provider.setLoading(false);
      provider.setError('Failed to analyze statement. Please check your network connection.');
    }
  }

  void _useDemoDataset() {
    final provider = Provider.of<AnalysisProvider>(context, listen: false);
    provider.setLoading(true);

    Future.delayed(const Duration(milliseconds: 600), () {
      final demoData = ApiService.getDemoData();
      provider.setAnalysisResult(demoData);
    });
  }

  Future<void> _syncConnectedBank() async {
    final provider = Provider.of<AnalysisProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    provider.setLoading(true);
    try {
      final result = await ApiService.connectBankAccount(
        bankName: provider.connectedBankName,
        token: authProvider.token,
      );
      provider.setAnalysisResult(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transactions synced with ${provider.connectedBankName}!', style: AppTypography.bodyMedium(color: AppColors.paper)),
          backgroundColor: AppColors.signalGreen,
        ),
      );
    } catch (e) {
      provider.setError('Failed to sync bank transactions.');
    }
  }

  Future<void> _disconnectBank() async {
    final provider = Provider.of<AnalysisProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await ApiService.disconnectBankAccount(authProvider.token);
    await provider.setBankConnection(isConnected: false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bank account disconnected successfully.', style: AppTypography.bodyMedium(color: AppColors.paper)),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                              'RECURRING LEAK DETECTOR',
                              style: AppTypography.eyebrow(color: AppColors.signalGreen).copyWith(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Import Financial Statement Data',
                        style: AppTypography.headlineMedium(color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect bank with one-click consent or upload PDF statements to analyze hidden leaks.',
                        style: AppTypography.bodySmall(color: AppColors.slate),
                      ),
                    ],
                  ),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _useDemoDataset,
                    icon: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.amber),
                    label: Text('Try Demo Dataset', style: AppTypography.labelBold(color: AppColors.ink).copyWith(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // MAIN 2-COLUMN SINGLE VIEW
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isNarrow = constraints.maxWidth < 840;

                    // LEFT PANEL: BANK INTEGRATION (RICH DETAILS & DENSE SPACING)
                    Widget bankPanel = Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: provider.isBankConnected ? AppColors.signalGreen.withValues(alpha: 0.05) : AppColors.paperDim,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: provider.isBankConnected ? AppColors.signalGreen : AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.signalGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      provider.isBankConnected ? Icons.check_circle_rounded : Icons.account_balance_rounded,
                                      color: AppColors.signalGreen,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.isBankConnected ? '${provider.connectedBankName} Linked' : 'Connect Bank Account',
                                        style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 16),
                                      ),
                                      Text(
                                        provider.isBankConnected ? 'Automated Sync Active' : 'Sandbox Integration',
                                        style: AppTypography.bodySmall(color: AppColors.slate).copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: provider.isBankConnected ? AppColors.signalGreen : AppColors.ink,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  provider.isBankConnected ? 'ACTIVE' : 'RECOMMENDED',
                                  style: AppTypography.eyebrow(color: AppColors.paper).copyWith(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Text(
                            provider.isBankConnected
                                ? 'Your ${provider.connectedBankName} account is connected. Statement entries are automatically synced to your database.'
                                : 'Connect your bank account with Sandbox consent to automatically fetch transactions without manual uploads.',
                            style: AppTypography.bodySmall(color: AppColors.slate).copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 16),

                          // RICH DETAILS GRID (ELIMINATES BLANK VOID)
                          if (provider.isBankConnected) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Column(
                                children: [
                                  _BankDetailRow(
                                    icon: Icons.account_balance_wallet_outlined,
                                    label: 'Account Type',
                                    value: 'Checking (*4821)',
                                  ),
                                  const Divider(color: AppColors.line, height: 16),
                                  _BankDetailRow(
                                    icon: Icons.receipt_rounded,
                                    label: 'Parsed Records',
                                    value: '${provider.allTransactions.isNotEmpty ? provider.allTransactions.length : 15} Transactions',
                                  ),
                                  const Divider(color: AppColors.line, height: 16),
                                  _BankDetailRow(
                                    icon: Icons.security_rounded,
                                    label: 'Data Access',
                                    value: 'Read-Only (OAuth 2.0)',
                                  ),
                                  const Divider(color: AppColors.line, height: 16),
                                  _BankDetailRow(
                                    icon: Icons.history_rounded,
                                    label: 'Sync Status',
                                    value: 'Real-time Auto-Sync',
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Column(
                                children: const [
                                  _BankDetailRow(
                                    icon: Icons.verified_user_outlined,
                                    label: 'Security',
                                    value: '256-bit Encrypted Consent',
                                  ),
                                  Divider(color: AppColors.line, height: 16),
                                  _BankDetailRow(
                                    icon: Icons.offline_pin_outlined,
                                    label: 'Integration Mode',
                                    value: 'Plaid Sandbox Demo',
                                  ),
                                  Divider(color: AppColors.line, height: 16),
                                  _BankDetailRow(
                                    icon: Icons.pin_outlined,
                                    label: 'Authentication',
                                    value: '4-Digit PIN Security',
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const Spacer(),

                          if (provider.isBankConnected) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.ink,
                                      foregroundColor: AppColors.paper,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _syncConnectedBank,
                                    icon: const Icon(Icons.sync_rounded, size: 16),
                                    label: Text('Sync Transactions', style: AppTypography.labelBold(color: AppColors.paper).copyWith(fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    side: const BorderSide(color: AppColors.line),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _disconnectBank,
                                  icon: const Icon(Icons.link_off_rounded, size: 16, color: AppColors.coral),
                                  label: Text('Disconnect', style: AppTypography.labelBold(color: AppColors.coral).copyWith(fontSize: 12)),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.signalGreen,
                                  foregroundColor: AppColors.paper,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => PlaidBankModal.show(context),
                                icon: const Icon(Icons.link_rounded, size: 18),
                                label: Text(
                                  'Connect Bank Account (Sandbox)',
                                  style: AppTypography.labelBold(color: AppColors.paper).copyWith(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );

                    // RIGHT PANEL: PDF STATEMENT UPLOADER
                    Widget uploadPanel = Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.upload_file_rounded, color: AppColors.ink, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Upload PDF Bank Statement',
                                style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select a PDF bank statement file to parse locally.',
                            style: AppTypography.bodySmall(color: AppColors.slate).copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 14),

                          Expanded(
                            child: provider.isLoading
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 36,
                                          width: 36,
                                          child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text('Analyzing statement...', style: AppTypography.labelBold(color: AppColors.ink)),
                                      ],
                                    ),
                                  )
                                : _needsPassword
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.lock_outline_rounded, color: AppColors.amber, size: 32),
                                          const SizedBox(height: 8),
                                          Text('Password Required', style: AppTypography.titleLarge(color: AppColors.ink).copyWith(fontSize: 15)),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _passwordController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              hintText: 'Enter PDF Password',
                                              errorText: _isWrongPassword ? 'Incorrect password' : null,
                                              filled: true,
                                              fillColor: AppColors.paperDim,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: AppColors.paper),
                                                  onPressed: () => _analyzeStatement(password: _passwordController.text),
                                                  child: Text('Unlock Statement', style: AppTypography.labelBold(color: AppColors.paper)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              TextButton(onPressed: _clearFile, child: Text('Cancel', style: AppTypography.monoSmall(color: AppColors.slate))),
                                            ],
                                          ),
                                        ],
                                      )
                                    : InkWell(
                                        onTap: _pickFile,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.paperDim,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.line, style: BorderStyle.solid),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.cloud_upload_outlined, size: 32, color: AppColors.slate),
                                              const SizedBox(height: 8),
                                              Text(
                                                _selectedFileName ?? 'Click to choose PDF Statement',
                                                style: AppTypography.labelBold(color: AppColors.ink).copyWith(fontSize: 13),
                                              ),
                                              if (_selectedFileSize != null)
                                                Text(
                                                  '${(_selectedFileSize! / 1024).toStringAsFixed(1)} KB',
                                                  style: AppTypography.monoSmall(color: AppColors.slate).copyWith(fontSize: 10),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                          ),
                          const SizedBox(height: 14),

                          if (_selectedFileName != null && !_needsPassword && !provider.isLoading)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.ink,
                                  foregroundColor: AppColors.paper,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _analyzeStatement(),
                                icon: const Icon(Icons.analytics_rounded, size: 16),
                                label: Text('Analyze Statement', style: AppTypography.labelBold(color: AppColors.paper).copyWith(fontSize: 13)),
                              ),
                            ),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            bankPanel,
                            const SizedBox(height: 20),
                            SizedBox(height: 280, child: uploadPanel),
                          ],
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: bankPanel),
                        const SizedBox(width: 24),
                        Expanded(child: uploadPanel),
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

class _BankDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BankDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.slate),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall(color: AppColors.slate).copyWith(fontSize: 12),
            ),
          ],
        ),
        Text(
          value,
          style: AppTypography.labelBold(color: AppColors.ink).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
