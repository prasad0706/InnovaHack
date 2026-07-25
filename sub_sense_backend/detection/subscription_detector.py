from collections import defaultdict
from datetime import datetime
from typing import List, Dict, Any

from detection.price_checker import detect_price_increase

KNOWN_SUBSCRIPTION_CATEGORIES = {
    "Entertainment", "Software", "AI Tools", "Music",
    "Cloud Services", "Fitness", "Career", "Food & Delivery"
}

def calculate_health_score(subscriptions: List[Dict[str, Any]]) -> int:
    if not subscriptions:
        return 100
    total_spend = sum(s["current_amount"] for s in subscriptions)
    leakage = sum(s["current_amount"] for s in subscriptions if s.get("recommended_action") != "Keep")
    if total_spend == 0:
        return 100
    ratio = leakage / total_spend
    score = round(100 - (ratio * 65))
    return max(15, min(98, score))

def detect_subscriptions(transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Rule-based subscription detector.
    Groups transactions by canonical merchant, sorts by date,
    calculates recurrence gaps & confidence, and assigns per-subscription action recommendations.
    Supports single-occurrence known subscription merchants for 1-month statements!
    """
    grouped = defaultdict(list)
    for t in transactions:
        grouped[t["merchant"]].append(t)

    subscriptions = []
    sub_index = 1

    for merchant, txns in grouped.items():
        txns.sort(key=lambda x: x["date"])

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
                if 22 <= avg_gap <= 38:
                    frequency = "monthly"
                    confidence = min(0.98, 0.6 + 0.12 * len(txns))
                elif 340 <= avg_gap <= 385:
                    frequency = "annual"
                    confidence = min(0.98, 0.6 + 0.12 * len(txns))
                else:
                    if category in KNOWN_SUBSCRIPTION_CATEGORIES:
                        frequency = "monthly"
                        confidence = 0.70
                    else:
                        continue
            except Exception:
                if category in KNOWN_SUBSCRIPTION_CATEGORIES:
                    confidence = 0.75
                else:
                    continue
        else:
            if category in KNOWN_SUBSCRIPTION_CATEGORIES:
                frequency = "monthly"
                confidence = 0.75
            else:
                continue

        price_change = detect_price_increase(history)

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
