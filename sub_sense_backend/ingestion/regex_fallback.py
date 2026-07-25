import re
from typing import List, Dict, Any

TXN_LINE_PATTERN = re.compile(
    r"(?P<date>\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}|\d{1,2}\s+[A-Za-z]{3}\s+\d{2,4})\s+"
    r"(?P<description>.+?)\s+"
    r"(?P<amount>[\d,]+\.\d{2})\s*"
    r"(?P<type>DR|CR|Debit|Credit)?\s*$",
    re.IGNORECASE
)

def fallback_parse(pdf) -> List[Dict[str, Any]]:
    """
    Tier 2 Regex fallback parser when table extraction fails.
    Extracts raw text from pdfplumber pages and parses line-by-line using regex patterns.
    """
    raw_transactions = []
    
    for page in pdf.pages:
        text = page.extract_text()
        if not text:
            continue
            
        for line in text.split("\n"):
            line = line.strip()
            if not line:
                continue
                
            m = TXN_LINE_PATTERN.search(line)
            if m:
                raw_transactions.append({
                    "date": m.group("date").strip(),
                    "description": m.group("description").strip(),
                    "debit": m.group("amount") if (m.group("type") or "").upper() in ("DR", "DEBIT") else "",
                    "credit": m.group("amount") if (m.group("type") or "").upper() in ("CR", "CREDIT") else "",
                    "amount": m.group("amount"),
                    "source": "pdf_regex",
                })
                
    return raw_transactions
