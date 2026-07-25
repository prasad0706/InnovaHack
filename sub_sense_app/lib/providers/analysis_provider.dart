import 'package:flutter/material.dart';
import '../models/subscription_model.dart';

class AnalysisProvider extends ChangeNotifier {
  bool _isAnalyzed = false;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> _summary = {};
  List<SubscriptionItem> _subscriptions = [];
  Set<String> _simulatedCancelledIds = {};

  bool get isAnalyzed => _isAnalyzed;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get summary => _summary;
  List<SubscriptionItem> get subscriptions => _subscriptions;
  Set<String> get simulatedCancelledIds => _simulatedCancelledIds;

  // Active Screen Navigation Tab Index
  int _activeTabIndex = 0;
  int get activeTabIndex => _activeTabIndex;

  void setActiveTab(int index) {
    if (index != 0 && !_isAnalyzed) return; // Prevent locked tab navigation
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

    // Default select all cancel/downgrade items in simulator
    _simulatedCancelledIds = _subscriptions
        .where((s) => s.recommendedAction != 'Keep')
        .map((s) => s.id)
        .toSet();

    _activeTabIndex = 1; // Auto navigate to Dashboard after upload
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

  void reset() {
    _isAnalyzed = false;
    _isLoading = false;
    _errorMessage = null;
    _summary = {};
    _subscriptions = [];
    _simulatedCancelledIds = {};
    _activeTabIndex = 0;
    notifyListeners();
  }

  // Derived Metrics
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

  int get cancelCount =>
      _subscriptions.where((s) => s.recommendedAction == 'Cancel').length;
}
