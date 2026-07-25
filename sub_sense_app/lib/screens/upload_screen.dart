import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/card_container.dart';

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
      provider.setAnalysisResult(ApiService.getDemoData());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STEP 1',
                style: AppTypography.eyebrow(color: AppColors.signalGreen),
              ),
              const SizedBox(height: 8),
              Text(
                'Find out where your money leaks.',
                style: AppTypography.headlineLarge(color: AppColors.ink),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload your PDF bank statement to automatically detect recurring subscriptions, silent price increases, and potential monthly savings.',
                style: AppTypography.bodyLarge(color: AppColors.slate),
              ),
              const SizedBox(height: 32),

              // Error Banner (if any non-password error)
              if (provider.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.coral, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.coral, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: AppTypography.bodyMedium(color: AppColors.coral),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Loading View
              if (provider.isLoading) ...[
                CardContainer(
                  backgroundColor: AppColors.paperDim,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Reading transactions & detecting subscriptions...',
                        style: AppTypography.titleLarge(color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scanning PDF tables, normalizing merchants, and checking price hikes.',
                        style: AppTypography.bodyMedium(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
              ]
              // Idle / File Picked View
              else ...[
                if (_selectedFileName == null) ...[
                  // Dropzone Container
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.ink.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.paperDim,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.upload_file_rounded,
                              size: 40,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Drag your statement PDF here',
                            style: AppTypography.titleLarge(color: AppColors.ink),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Supports HDFC, ICICI, SBI, Axis & all standard Indian bank statements',
                            style: AppTypography.bodySmall(color: AppColors.slate),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.ink,
                              foregroundColor: AppColors.paper,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _pickFile,
                            icon: const Icon(Icons.folder_open_rounded, size: 18),
                            label: Text(
                              'Choose PDF file',
                              style: AppTypography.labelBold(color: AppColors.paper),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Demo dataset trigger button for hackathon judges
                  Center(
                    child: TextButton.icon(
                      onPressed: _useDemoDataset,
                      icon: const Icon(Icons.auto_awesome_rounded,
                          size: 16, color: AppColors.signalGreen),
                      label: Text(
                        'Try with demo dataset (Sample statement with price hikes)',
                        style: AppTypography.bodyMedium(
                          color: AppColors.signalGreen,
                        ).copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ] else ...[
                  // File Selected Row Card
                  CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded,
                                color: AppColors.coral, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFileName!,
                                    style: AppTypography.labelBold(
                                        color: AppColors.ink),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedFileSize != null
                                        ? '${(_selectedFileSize! / 1024).toStringAsFixed(1)} KB'
                                        : 'PDF File',
                                    style: AppTypography.bodySmall(
                                        color: AppColors.slate),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _clearFile,
                              icon: const Icon(Icons.close_rounded,
                                  color: AppColors.slate),
                              tooltip: 'Remove file',
                            ),
                          ],
                        ),

                        // Password Input Panel (if protected PDF)
                        if (_needsPassword) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isWrongPassword
                                  ? AppColors.coral.withValues(alpha: 0.1)
                                  : AppColors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isWrongPassword
                                    ? AppColors.coral
                                    : AppColors.amber,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 18,
                                      color: _isWrongPassword
                                          ? AppColors.coral
                                          : AppColors.amber,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isWrongPassword
                                          ? 'Incorrect Password'
                                          : 'This PDF is password-protected',
                                      style: AppTypography.labelBold(
                                        color: _isWrongPassword
                                            ? AppColors.coral
                                            : AppColors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isWrongPassword
                                      ? 'The password entered did not match. Please verify and try again.'
                                      : 'Bank statement passwords are often your Date of Birth (DDMMYYYY) or Name + DOB.',
                                  style: AppTypography.bodySmall(
                                      color: AppColors.ink),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          hintText: 'Enter PDF password',
                                          hintStyle: AppTypography.bodyMedium(
                                              color: AppColors.slate),
                                          filled: true,
                                          fillColor: AppColors.paper,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: AppColors.line),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.ink,
                                        foregroundColor: AppColors.paper,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => _analyzeStatement(
                                        password: _passwordController.text,
                                      ),
                                      child: Text(
                                        'Unlock & Analyze',
                                        style: AppTypography.labelBold(
                                            color: AppColors.paper),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (!_needsPassword) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ink,
                                foregroundColor: AppColors.paper,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _analyzeStatement(),
                              icon: const Icon(Icons.analytics_rounded,
                                  size: 18),
                              label: Text(
                                'Analyze Statement',
                                style: AppTypography.labelBold(
                                    color: AppColors.paper),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
