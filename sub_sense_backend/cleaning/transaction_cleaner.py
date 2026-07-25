import re
from typing import List, Dict, Any
from datetime import datetime

DATE_FORMATS = [
    "%d/%m/%Y", "%d-%m-%Y", "%d.%m.%Y",
    "%d/%m/%y", "%d-%m-%y", "%d.%m.%y",
    "%Y-%m-%d", "%d %b %Y", "%d %B %Y",
]

def parse_date(date_str: str) -> str:
    date_str = date_str.strip()
    for fmt in DATE_FORMATS:
        try:
            dt = datetime.strptime(date_str, fmt)
            return dt.strftime("%Y-%m-%d")
        except ValueError:
            continue
    # Fallback to current year format if partial
    return date_str

def parse_amount(val: str) -> float:
    if not val:
        return 0.0
    # Strip currency symbols, commas
    cleaned = re.sub(r"[^\d.]", "", val)
    try:
        return float(cleaned)
    except ValueError:
        return 0.0

NON_SUBSCRIPTION_KEYWORDS = [
    "salary", "interest credit", "atm withdrawal", "cash deposit",
    "neft cr", "rtgs cr", "refund", "cashback", "dividend"
]

def clean_transactions(raw_list: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    cleaned = []
    seen = set()
    
    for item in raw_list:
        desc = (item.get("description") or item.get("narration") or item.get("raw_description") or "").strip()
        desc_lower = desc.lower()
        
        # Filter non-subscription debit rows
        if any(kw in desc_lower for kw in NON_SUBSCRIPTION_KEYWORDS):
            continue
            
        # Determine amount & type
        debit_amt = parse_amount(item.get("debit", ""))
        credit_amt = parse_amount(item.get("credit", ""))
        generic_amt = parse_amount(item.get("amount", ""))
        
        if credit_amt > 0 and debit_amt == 0:
            continue # Skip credit transactions
            
        amt = debit_amt if debit_amt > 0 else generic_amt
        if amt <= 0:
            continue
            
        iso_date = parse_date(item.get("date", ""))
        
        # Deduplication key (date + amount + description snippet)
        dedup_key = (iso_date, amt, desc[:20].lower())
        if dedup_key in seen:
            continue
        seen.add(dedup_key)
        
        cleaned.append({
            "date": iso_date,
            "raw_description": desc,
            "amount": amt,
            "type": "debit",
            "source": item.get("source", "pdf_table"),
        })
        
    return cleaned
