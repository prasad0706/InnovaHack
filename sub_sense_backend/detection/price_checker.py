import statistics
from typing import List, Dict, Any, Optional

def detect_price_increase(history: List[Dict[str, Any]], threshold_pct: float = 5.0, threshold_abs: float = 50.0) -> Optional[Dict[str, Any]]:
    """
    Determines if the latest transaction in payment history represents a price hike.
    Baseline = median of all preceding transactions.
    """
    if len(history) < 2:
        return {"increased": False, "amount_change": 0.0, "percent_change": 0.0}

    amounts = [h["amount"] for h in history]
    baseline = statistics.median(amounts[:-1])
    latest = amounts[-1]
    
    change = latest - baseline
    pct = (change / baseline * 100.0) if baseline > 0 else 0.0

    if change >= threshold_abs or pct >= threshold_pct:
        return {
            "increased": True,
            "amount_change": round(change, 2),
            "percent_change": round(pct, 1),
        }

    return {"increased": False, "amount_change": 0.0, "percent_change": 0.0}
