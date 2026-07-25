import re
import json
import os
from typing import List, Dict, Any
from rapidfuzz import process, fuzz

# Load merchant database
KB_PATH = os.path.join(os.path.dirname(__file__), "..", "knowledge_base", "merchants.json")

MERCHANT_DB = {}
if os.path.exists(KB_PATH):
    with open(KB_PATH, "r", encoding="utf-8") as f:
        MERCHANT_DB = json.load(f)

def strip_noise(desc: str) -> str:
    desc = re.sub(r"UPI[/\-]?\d+", "", desc, flags=re.I)
    desc = re.sub(r"\b(PVT|LTD|INDIA|IN|COM|INC|CORP|PAYMENT|AUTOPAY|BILL)\b", "", desc, flags=re.I)
    desc = re.sub(r"[/\-]?\d{6,}", "", desc) # Remove long transaction ref numbers
    desc = re.sub(r"\s+", " ", desc).strip()
    return desc

def normalize_merchant(raw_desc: str) -> Dict[str, str]:
    cleaned = strip_noise(raw_desc).lower()
    
    if not cleaned:
        return {"canonical": raw_desc.title(), "category": "General"}
        
    # Match against known merchant dictionary
    for key, val in MERCHANT_DB.items():
        if key in cleaned:
            return {"canonical": val["canonical"], "category": val["category"]}
            
    # Fuzzy match fallback
    known_keys = list(MERCHANT_DB.keys())
    if known_keys:
        res = process.extractOne(cleaned, known_keys, scorer=fuzz.partial_ratio)
        if res and res[1] >= 80:
            matched_key = res[0]
            return {
                "canonical": MERCHANT_DB[matched_key]["canonical"],
                "category": MERCHANT_DB[matched_key]["category"],
            }
            
    # Default fallback to title case of cleaned description
    return {
        "canonical": cleaned.title() if cleaned else raw_desc.title(),
        "category": "General",
    }

def normalize_transactions(transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    for t in transactions:
        norm = normalize_merchant(t["raw_description"])
        t["merchant"] = norm["canonical"]
        t["category"] = norm["category"]
    return transactions
