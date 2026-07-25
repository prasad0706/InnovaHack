import os, sys
sys.stdout.reconfigure(encoding='utf-8')

from ingestion.pdf_loader import load_pdf, PDFPasswordException
from ingestion.table_extractor import extract_tables_from_pdf
from ingestion.regex_fallback import fallback_parse
from cleaning.transaction_cleaner import clean_transactions
from cleaning.merchant_normalizer import normalize_transactions
from detection.subscription_detector import detect_subscriptions

def test_file(filepath, password=None):
    print(f"\n==================================================")
    print(f"Testing: {os.path.basename(filepath)}")
    print(f"==================================================")

    with open(filepath, "rb") as f:
        file_bytes = f.read()

    try:
        pdf = load_pdf(file_bytes, password=password)
    except PDFPasswordException as e:
        print(f"🔒 Password Protected PDF triggered! Exception Code: {e.code}")
        print(f"   Message: {e.message}")
        if not password:
            print("   Retrying with password 'pass123'...")
            test_file(filepath, password="pass123")
        return

    method = "Tier 1 Table Extractor"
    raw_txns = extract_tables_from_pdf(pdf)

    if len(raw_txns) < 3:
        method = "Tier 2 Regex Fallback"
        raw_txns = fallback_parse(pdf)

    pdf.close()

    cleaned = clean_transactions(raw_txns)
    normalized = normalize_transactions(cleaned)
    subs = detect_subscriptions(normalized)

    print(f"Extraction Method Used: {method}")
    print(f"Cleaned Transactions: {len(cleaned)}")
    print(f"Subscriptions Detected: {len(subs)}\n")

    for s in subs:
        hike_str = f" 🚨 PRICE HIKE +{s['price_change']['percent_change']}% (+₹{s['price_change']['amount_change']})" if s['price_change']['increased'] else ""
        print(f"• {s['merchant']} ({s['category']}) - ₹{s['current_amount']} [{s['recommended_action']}]{hike_str}")

if __name__ == "__main__":
    target_dir = r"c:\Users\Prasad\Downloads\InnovaHack\testing"
    files = ["hdfc_statement.pdf", "icici_statement.pdf", "icici_protected_pass123.pdf", "sbi_statement.pdf", "axis_text_layout.pdf"]

    for fname in files:
        fpath = os.path.join(target_dir, fname)
        if os.path.exists(fpath):
            test_file(fpath)
