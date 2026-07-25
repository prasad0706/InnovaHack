class PaymentHistoryItem {
  final String date;
  final double amount;

  PaymentHistoryItem({required this.date, required this.amount});

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      date: json['date'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'amount': amount,
      };
}

class PriceChange {
  final bool increased;
  final double amountChange;
  final double percentChange;

  PriceChange({
    required this.increased,
    required this.amountChange,
    required this.percentChange,
  });

  factory PriceChange.fromJson(Map<String, dynamic> json) {
    return PriceChange(
      increased: json['increased'] as bool? ?? false,
      amountChange: (json['amount_change'] as num?)?.toDouble() ?? 0.0,
      percentChange: (json['percent_change'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SubscriptionItem {
  final String id;
  final String merchant;
  final String category;
  final String frequency;
  final double currentAmount;
  final double confidence;
  final PriceChange? priceChange;
  final List<PaymentHistoryItem> history;
  final String recommendedAction; // 'Cancel', 'Downgrade', 'Keep'
  final String actionReason;
  final double monthlySaving;

  SubscriptionItem({
    required this.id,
    required this.merchant,
    required this.category,
    required this.frequency,
    required this.currentAmount,
    required this.confidence,
    this.priceChange,
    required this.history,
    required this.recommendedAction,
    required this.actionReason,
    required this.monthlySaving,
  });

  factory SubscriptionItem.fromJson(Map<String, dynamic> json, int index) {
    final priceChangeJson = json['price_change'] as Map<String, dynamic>?;
    final historyList = (json['history'] as List<dynamic>? ?? [])
        .map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();

    bool isHike = priceChangeJson != null &&
        (priceChangeJson['increased'] as bool? ?? false);

    // Derive recommendation client-side if not explicitly provided
    String action = json['recommended_action'] as String? ?? 'Keep';
    String reason = json['action_reason'] as String? ?? 'Regular usage';
    double saving = (json['monthly_saving'] as num?)?.toDouble() ?? 0.0;

    if (json['recommended_action'] == null) {
      if (isHike) {
        action = 'Downgrade';
        reason =
            'Price increased by ${priceChangeJson['percent_change']}% recently';
        saving = (priceChangeJson['amount_change'] as num).toDouble();
      } else if (json['category'] == 'Entertainment' &&
          (json['current_amount'] as num) > 500) {
        action = 'Cancel';
        reason = 'High monthly spending on non-essential service';
        saving = (json['current_amount'] as num).toDouble();
      }
    }

    return SubscriptionItem(
      id: json['id'] as String? ?? 'sub_$index',
      merchant: json['merchant'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'General',
      frequency: json['frequency'] as String? ?? 'monthly',
      currentAmount: (json['current_amount'] as num).toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.9,
      priceChange: priceChangeJson != null
          ? PriceChange.fromJson(priceChangeJson)
          : null,
      history: historyList,
      recommendedAction: action,
      actionReason: reason,
      monthlySaving: saving,
    );
  }
}
