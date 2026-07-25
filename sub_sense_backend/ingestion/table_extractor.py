from typing import List, Dict, Any, Optional
from rapidfuzz import process

COLUMN_ALIASES = {
    "date": ["date", "txn date", "value date", "transaction date", "post date", "dt"],
    "description": ["narration", "description", "particulars", "details", "remarks", "transaction details"],
    "debit": ["debit", "withdrawal", "dr", "debit amount", "withdrawals"],
    "credit": ["credit", "deposit", "cr", "credit amount", "deposits"],
    "amount": ["amount", "txn amount", "amount (rs)"],
    "balance": ["balance", "closing balance", "running balance", "bal"],
}

def match_column(header_cell: str) -> Optional[str]:
    if not header_cell:
        return None
    cleaned = header_cell.lower().strip()
    for canonical, aliases in COLUMN_ALIASES.items():
        res = process.extractOne(cleaned, aliases)
        if res and res[1] >= 75:
            return canonical
    return None

def extract_tables_from_pdf(pdf) -> List[Dict[str, Any]]:
    """
    Tier 1 generic table extractor.
    Iterates over pages, extracts tables, matches headers dynamically,
    and returns list of standardized raw transaction dictionaries.
    """
    raw_transactions = []
    
    for page in pdf.pages:
        # Strategy 1: strict line-based grid
        tables = page.extract_tables({
            "vertical_strategy": "lines_strict",
            "horizontal_strategy": "lines_strict",
        })
        
        # Fallback Strategy 2: text alignment
        if not tables or all(len(t) == 0 for t in tables):
            tables = page.extract_tables({
                "vertical_strategy": "text",
                "horizontal_strategy": "text",
            })
            
        for table in tables:
            if not table or len(table) < 2:
                continue
                
            # Header analysis
            header_row = table[0]
            col_map = {}
            for idx, cell in enumerate(header_row):
                if cell:
                    col_name = match_column(str(cell))
                    if col_name:
                        col_map[col_name] = idx
                        
            # Must at least identify date, description, and an amount/debit column
            if "date" not in col_map or "description" not in col_map:
                continue
                
            for row in table[1:]:
                if not row or len(row) <= max(col_map.values(), default=0):
                    continue
                    
                date_val = str(row[col_map["date"]]).strip() if row[col_map["date"]] else ""
                desc_val = str(row[col_map["description"]]).strip() if row[col_map["description"]] else ""
                
                if not date_val or not desc_val or date_val.lower() == "date":
                    continue
                    
                debit_val = str(row[col_map["debit"]]).strip() if "debit" in col_map and row[col_map["debit"]] else ""
                credit_val = str(row[col_map["credit"]]).strip() if "credit" in col_map and row[col_map["credit"]] else ""
                amount_val = str(row[col_map["amount"]]).strip() if "amount" in col_map and row[col_map["amount"]] else ""
                
                raw_transactions.append({
                    "date": date_val,
                    "description": desc_val,
                    "debit": debit_val,
                    "credit": credit_val,
                    "amount": amount_val,
                    "source": "pdf_table",
                })
                
    return raw_transactions
