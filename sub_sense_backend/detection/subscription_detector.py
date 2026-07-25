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
        elif category in ("Entertainment", "Software") and currentAmount > 500:
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
