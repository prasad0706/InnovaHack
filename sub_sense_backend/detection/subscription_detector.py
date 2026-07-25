from collections import defaultdict
from datetime import datetime
from typing import List, Dict, Any

from detection.price_checker import detect_price_increase

def detect_subscriptions(transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Rule-based subscription detector.
    Groups transactions by canonical merchant, sorts by date,
    calculates recurrence gaps & confidence, and assigns per-subscription action recommendations.
    """
    grouped = defaultdict(list)
    for t in transactions:
        grouped[t["merchant"]].append(t)

    subscriptions = []
    sub_index = 1

    for merchant, txns in grouped.items():
        # Sort transactions chronologically
        txns.sort(key=lambda x: x["date"])

        # Create history items list
        history = [{"date": t["date"], "amount": t["amount"]} for t in txns]
        current_amount = txns[-1]["amount"]
        category = txns[0]["category"]

        frequency = "monthly"
        confidence = 0.85

        if len(txns) >= 2:
            try:
                gaps = []
                for i in range(len(txns) - 1):
                    d1 = datetime.strptime(txns[i]["date"], "%Y-%m-%d")
                    d2 = datetime.strptime(txns[i+1]["date"], "%Y-%m-%d")
                    gaps.append((d2 - d1).days)

                avg_gap = sum(gaps) / len(gaps)
                if 25 <= avg_gap <= 35:
                    frequency = "monthly"
                    confidence = min(0.98, 0.6 + 0.12 * len(txns))
                elif 350 <= avg_gap <= 380:
                    frequency = "annual"
                    confidence = min(0.98, 0.6 + 0.12 * len(txns))
                else:
                    # Skip if gaps don't resemble subscription recurrence
                    continue
            except Exception:
                confidence = 0.75
        else:
            # Single transaction - only include if recognized subscription merchant
            if category == "General":
                continue
            confidence = 0.70

        # Check price increase
        price_change = detect_price_increase(history)

        # Derive action recommendation
        action = "Keep"
        reason = "Regular usage, standard pricing."
        monthly_saving = 0.0

        if price_change.get("increased"):
            action = "Downgrade"
            reason = f"Price increased by {price_change['percent_change']}% recently (+₹{price_change['amount_change']})."
            monthly_saving = price_change["amount_change"]
        elif category in ("Entertainment", "Software") and current_amount > 500:
            action = "Cancel"
            reason = f"Unused high-cost {category.lower()} subscription."
            monthly_saving = current_amount
        elif category == "Duplicate":
            action = "Cancel"
            reason = "Duplicate service detected in same category."
            monthly_saving = current_amount

        subscriptions.append({
            "id": f"sub_{sub_index}",
            "merchant": merchant,
            "category": category,
            "frequency": frequency,
            "current_amount": current_amount,
            "confidence": round(confidence, 2),
            "price_change": price_change,
            "history": history,
            "recommended_action": action,
            "action_reason": reason,
            "monthly_saving": monthly_saving,
        })
        sub_index += 1

    return subscriptions


def calculate_health_score(subscriptions: List[Dict[str, Any]]) -> int:
    """
    Calculate the baseline Financial Health / Leak Score using the same formula
    as the client-side Flutter implementation.
    """
    if not subscriptions:
        return 100

    total_spend = 0.0
    leakage = 0.0
    price_hikes_count = 0
    high_cost_non_essentials_count = 0
    category_counts = {}

    for s in subscriptions:
        amount = s["current_amount"]
        action = s.get("recommended_action", "Keep")
        has_price_hike = s.get("price_change", {}).get("increased", False)
        category = s.get("category", "General")

        total_spend += amount
        if action != "Keep":
            leakage += amount

        if has_price_hike:
            price_hikes_count += 1

        if action == "Cancel" and amount > 500:
            high_cost_non_essentials_count += 1

        category_counts[category] = category_counts.get(category, 0) + 1

    if total_spend == 0:
        return 100

    # 1. Leakage Ratio Penalty (Max -50 points)
    leakage_ratio = leakage / total_spend
    leakage_penalty = leakage_ratio * 50

    # 2. Price Hike Penalty (-5 points per hike)
    price_hike_penalty = price_hikes_count * 5.0

    # 3. Duplicate Subscriptions Penalty (-10 points per category with duplicates)
    duplicate_categories_count = 0
    for cat, count in category_counts.items():
        if count > 1:
            duplicate_categories_count += 1

    # Also count explicit 'Duplicate' category if any
    explicit_duplicates = sum(1 for s in subscriptions if s.get("category") == "Duplicate")
    duplicate_penalty = (duplicate_categories_count + explicit_duplicates) * 10.0

    # 4. High-Cost Non-Essential Penalty (-5 points each)
    high_cost_penalty = high_cost_non_essentials_count * 5.0

    raw_score = 100 - leakage_penalty - price_hike_penalty - duplicate_penalty - high_cost_penalty
    return max(15, min(98, round(raw_score)))
