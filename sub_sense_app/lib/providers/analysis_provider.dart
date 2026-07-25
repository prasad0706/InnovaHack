import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../models/transaction_model.dart';
import '../utils/safe_storage.dart';

class AnalysisProvider extends ChangeNotifier {
  bool _isAnalyzed = false;
  bool _isLoading = false;
  String? _errorMessage;

  String _userName = 'Vedant';
  String _accountLabel = 'Primary Bank Account';
  double _monthlySavingsGoal = 3000.0;

  bool _isBankConnected = false;
  String _connectedBankName = 'HDFC Bank';

  Map<String, dynamic> _summary = {};
  List<SubscriptionItem> _subscriptions = [];
  List<TransactionRecord> _allTransactions = [];
  Set<String> _simulatedCancelledIds = {};

  bool get isAnalyzed => _isAnalyzed;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get userName => _userName;
  String get accountLabel => _accountLabel;
  double get monthlySavingsGoal => _monthlySavingsGoal;

  bool get isBankConnected => _isBankConnected;
  String get connectedBankName => _connectedBankName;

  Map<String, dynamic> get summary => _summary;
  List<SubscriptionItem> get subscriptions => _subscriptions;
  List<TransactionRecord> get allTransactions => _allTransactions;
  Set<String> get simulatedCancelledIds => _simulatedCancelledIds;

  int _activeTabIndex = 0;
  int get activeTabIndex => _activeTabIndex;

  void setTab(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  AnalysisProvider() {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    try {
      _userName = (await SafeStorage.getString('user_name')) ?? 'Vedant';
      _accountLabel = (await SafeStorage.getString('account_label')) ?? 'Primary Bank Account';
      _monthlySavingsGoal = (await SafeStorage.getDouble('monthly_savings_goal')) ?? 3000.0;
      _isBankConnected = (await SafeStorage.getBool('is_bank_connected')) ?? false;
      _connectedBankName = (await SafeStorage.getString('connected_bank_name')) ?? 'HDFC Bank';

      final savedJson = await SafeStorage.getString('cached_analysis_data');
      if (savedJson != null) {
        final data = jsonDecode(savedJson) as Map<String, dynamic>;
        _summary = data['summary'] as Map<String, dynamic>? ?? {};

        final rawSubs = (data['subscriptions'] as List<dynamic>? ?? []);
        _subscriptions = rawSubs
            .asMap()
            .entries
            .map((entry) => SubscriptionItem.fromJson(
                  entry.value as Map<String, dynamic>,
                  entry.key,
                ))
            .toList();

        final rawTxns = (data['all_transactions'] as List<dynamic>? ?? []);
        _allTransactions = rawTxns
            .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        _allTransactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        _simulatedCancelledIds = _subscriptions
            .where((s) => s.recommendedAction != 'Keep')
            .map((s) => s.id)
            .toSet();

        _isAnalyzed = true;
      }
    } catch (e) {
      debugPrint('Failed to load cached analysis: $e');
    }
    notifyListeners();
  }

  Future<void> _saveToPreferences(Map<String, dynamic> data) async {
    try {
      await SafeStorage.setString('cached_analysis_data', jsonEncode(data));
      await SafeStorage.setString('user_name', _userName);
      await SafeStorage.setString('account_label', _accountLabel);
      await SafeStorage.setDouble('monthly_savings_goal', _monthlySavingsGoal);
      await SafeStorage.setBool('is_bank_connected', _isBankConnected);
      await SafeStorage.setString('connected_bank_name', _connectedBankName);
    } catch (e) {
      debugPrint('Failed to save analysis cache: $e');
    }
  }

  Future<void> setBankConnection({required bool isConnected, String? bankName}) async {
    _isBankConnected = isConnected;
    if (bankName != null && bankName.isNotEmpty) {
      _connectedBankName = bankName;
      _accountLabel = '$bankName Account';
    }
    try {
      await SafeStorage.setBool('is_bank_connected', _isBankConnected);
      await SafeStorage.setString('connected_bank_name', _connectedBankName);
      await SafeStorage.setString('account_label', _accountLabel);
    } catch (e) {
      debugPrint('Failed to set bank connection state: $e');
    }
    notifyListeners();
  }

  Future<void> updateUserProfile({
    String? name,
    String? label,
    double? goal,
  }) async {
    if (name != null) _userName = name;
    if (label != null) _accountLabel = label;
    if (goal != null) _monthlySavingsGoal = goal;

    try {
      await SafeStorage.setString('user_name', _userName);
      await SafeStorage.setString('account_label', _accountLabel);
      await SafeStorage.setDouble('monthly_savings_goal', _monthlySavingsGoal);
    } catch (e) {
      debugPrint('Failed to update profile: $e');
    }
    notifyListeners();
  }

  void setActiveTab(int index) {
    if (index != 0 && !_isAnalyzed) return;
    _activeTabIndex = index;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void setAnalysisResult(Map<String, dynamic> data) {
    _isLoading = false;
    _errorMessage = null;
    _isAnalyzed = true;

    if (data['is_bank_connected'] == true || data['summary']?['bank_connected'] != null) {
      _isBankConnected = true;
      if (data['connected_bank'] != null) {
        _connectedBankName = data['connected_bank'];
      } else if (data['summary']?['bank_connected'] != null) {
        _connectedBankName = data['summary']['bank_connected'];
      }
      _accountLabel = '$_connectedBankName Account';
    }

    _summary = data['summary'] as Map<String, dynamic>? ?? {};

    final rawSubs = (data['subscriptions'] as List<dynamic>? ?? []);
    _subscriptions = rawSubs
        .asMap()
        .entries
        .map((entry) => SubscriptionItem.fromJson(
              entry.value as Map<String, dynamic>,
              entry.key,
            ))
        .toList();

    final rawTxns = (data['all_transactions'] as List<dynamic>? ?? []);
    _allTransactions = rawTxns
        .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    _allTransactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    _simulatedCancelledIds = _subscriptions
        .where((s) => s.recommendedAction != 'Keep')
        .map((s) => s.id)
        .toSet();

    _saveToPreferences(data);

    _activeTabIndex = 1;
    notifyListeners();
  }

  void toggleSimulatorAction(String subId) {
    if (_simulatedCancelledIds.contains(subId)) {
      _simulatedCancelledIds.remove(subId);
    } else {
      _simulatedCancelledIds.add(subId);
    }
    notifyListeners();
  }

  void selectAllSimulatorActions() {
    _simulatedCancelledIds = _subscriptions
        .where((s) => s.recommendedAction != 'Keep')
        .map((s) => s.id)
        .toSet();
    notifyListeners();
  }

  void resetSimulatorActions() {
    _simulatedCancelledIds.clear();
    notifyListeners();
  }

  Future<void> reset() async {
    _isAnalyzed = false;
    _isLoading = false;
    _errorMessage = null;
    _isBankConnected = false;
    _summary = {};
    _subscriptions = [];
    _allTransactions = [];
    _simulatedCancelledIds = {};
    _activeTabIndex = 0;

    try {
      await SafeStorage.remove('cached_analysis_data');
      await SafeStorage.setBool('is_bank_connected', false);
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
    notifyListeners();
  }

  int get baseHealthScore {
    if (!_isAnalyzed || _subscriptions.isEmpty) return 100;
    double totalSpend = _subscriptions.fold(0, (sum, s) => sum + s.currentAmount);
    double leakage = _subscriptions
        .where((s) => s.recommendedAction != 'Keep')
        .fold(0, (sum, s) => sum + s.currentAmount);

    if (totalSpend == 0) return 100;
    double ratio = leakage / totalSpend;
    int score = (100 - (ratio * 65)).round();
    return score.clamp(15, 98);
  }

  int get simulatedHealthScore {
    if (!_isAnalyzed || _subscriptions.isEmpty) return 100;
    double totalSpend = _subscriptions.fold(0, (sum, s) => sum + s.currentAmount);
    double remainingLeakage = _subscriptions
        .where((s) =>
            s.recommendedAction != 'Keep' &&
            !_simulatedCancelledIds.contains(s.id))
        .fold(0, (sum, s) => sum + s.currentAmount);

    if (totalSpend == 0) return 100;
    double ratio = remainingLeakage / totalSpend;
    int score = (100 - (ratio * 65)).round();
    return score.clamp(15, 98);
  }

  double get monthlyLeakage => _subscriptions
      .where((s) => s.recommendedAction != 'Keep')
      .fold(0, (sum, s) => sum + s.currentAmount);

  double get potentialMonthlySavings => _subscriptions
      .where((s) => s.recommendedAction != 'Keep')
      .fold(0, (sum, s) => sum + s.monthlySaving);

  double get simulatedMonthlySavings => _subscriptions
      .where((s) => _simulatedCancelledIds.contains(s.id))
      .fold(0, (sum, s) => sum + s.monthlySaving);

  double get simulatedAnnualSavings => simulatedMonthlySavings * 12;

  int get priceIncreaseCount =>
      _subscriptions.where((s) => s.priceChange?.increased == true).length;

  int get duplicateCount =>
      _subscriptions.where((s) => s.category == 'Duplicate').length;
}
