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
        .map(
          (entry) => SubscriptionItem.fromJson(
            entry.value as Map<String, dynamic>,
            entry.key,
          ),
        )
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

  int _calculateHealthScore({
    required List<SubscriptionItem> subscriptions,
    required Set<String> cancelledIds,
  }) {
    if (subscriptions.isEmpty) return 100;

    double totalSpend = 0;
    double leakage = 0;
    int priceHikesCount = 0;
    int highCostNonEssentialsCount = 0;
    Map<String, int> categoryCounts = {};

    for (var s in subscriptions) {
      bool isActioned = cancelledIds.contains(s.id);
      
      double simulatedAmount = s.current_amount;
      String simulatedAction = s.recommendedAction;
      bool hasPriceHike = s.priceChange?.increased ?? false;

      if (isActioned) {
        if (s.recommendedAction == 'Cancel') {
          continue;
        } else if (s.recommendedAction == 'Downgrade') {
          simulatedAmount = s.current_amount - s.monthlySaving;
          simulatedAction = 'Keep';
          hasPriceHike = false;
        }
      }

      totalSpend += simulatedAmount;
      if (simulatedAction != 'Keep') {
        leakage += simulatedAmount;
      }

      if (hasPriceHike) {
        priceHikesCount++;
      }

      if (simulatedAction == 'Cancel' && simulatedAmount > 500) {
        highCostNonEssentialsCount++;
      }

      // Track active subscriptions in categories (excluding 'Duplicate' category if we are mapping duplicates)
      String cat = s.category;
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    if (totalSpend == 0) return 100;

    // 1. Leakage Ratio Penalty (Max -50 points)
    double leakageRatio = leakage / totalSpend;
    double leakagePenalty = leakageRatio * 50;

    // 2. Price Hike Penalty (-5 points per hike)
    double priceHikePenalty = priceHikesCount * 5.0;

    // 3. Duplicate Subscriptions Penalty (-10 points per category with duplicates)
    int duplicateCategoriesCount = 0;
    categoryCounts.forEach((category, count) {
      if (count > 1) {
        duplicateCategoriesCount++;
      }
    });
    // Also include explicit 'Duplicate' categories or count from backend
    int explicitDuplicates = subscriptions
        .where((s) => !cancelledIds.contains(s.id) && s.category == 'Duplicate')
        .length;
    double duplicatePenalty = (duplicateCategoriesCount + explicitDuplicates) * 10.0;

    // 4. High-Cost Non-Essential Penalty (-5 points each)
    double highCostPenalty = highCostNonEssentialsCount * 5.0;

    double rawScore = 100 - leakagePenalty - priceHikePenalty - duplicatePenalty - highCostPenalty;
    return rawScore.round().clamp(15, 98);
  }

  // Derived Metrics
  int get baseHealthScore {
    if (!_isAnalyzed || _subscriptions.isEmpty) return 100;
    return _calculateHealthScore(
      subscriptions: _subscriptions,
      cancelledIds: const {},
    );
  }

  int get simulatedHealthScore {
    if (!_isAnalyzed || _subscriptions.isEmpty) return 100;
    return _calculateHealthScore(
      subscriptions: _subscriptions,
      cancelledIds: _simulatedCancelledIds,
    );
  }

  double get monthlyLeakage => _subscriptions
      .where((s) => s.recommendedAction != 'Keep')
      .fold(0, (sum, s) => sum + s.current_amount);

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
