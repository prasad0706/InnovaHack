import sys
sys.stdout.reconfigure(encoding='utf-8')
import database

print("=== TESTING USER PROFILE BANK CONNECTION & INCREMENTAL PDF MERGING ===")

# 1. Update user bank connection
status1 = database.update_user_bank_connection("user_1001", "HDFC Bank", is_connected=True)
print("✅ Connected Bank:", status1)

# 2. Merge First Statement (Jan - Mar 2026)
txns_batch_1 = [
    {"date": "2026-03-05", "raw_description": "UPI/NETFLIX.COM", "merchant": "Netflix", "category": "Entertainment", "amount": 499.0},
    {"date": "2026-02-05", "raw_description": "UPI/NETFLIX.COM", "merchant": "Netflix", "category": "Entertainment", "amount": 499.0},
    {"date": "2026-01-05", "raw_description": "UPI/NETFLIX.COM", "merchant": "Netflix", "category": "Entertainment", "amount": 499.0},
]
database.merge_and_save_analysis("user_1001", {}, [], txns_batch_1)
print("✅ Saved Batch 1 (3 entries)")

# 3. Upload Second PDF Statement (Apr - Jul 2026 with Price Hike)
txns_batch_2 = [
    {"date": "2026-07-05", "raw_description": "UPI/NETFLIX.COM", "merchant": "Netflix", "category": "Entertainment", "amount": 649.0},
    {"date": "2026-06-05", "raw_description": "UPI/NETFLIX.COM", "merchant": "Netflix", "category": "Entertainment", "amount": 649.0},
    {"date": "2026-05-05", "raw_description": "UPI/NETFLIX.COM", "merchant": "Netflix", "category": "Entertainment", "amount": 649.0},
    {"date": "2026-04-05", "raw_description": "UPI/NETFLIX.COM", "merchant": "Netflix", "category": "Entertainment", "amount": 499.0},
]
database.merge_and_save_analysis("user_1001", {}, [], txns_batch_2)

# 4. Retrieve combined profile history
latest = database.get_latest_analysis("user_1001")
print(f"✅ Combined Master Ledger Entries: {len(latest['all_transactions'])}")
print("   - Dates (Chronological Descending):", [t['date'] for t in latest['all_transactions']])

# 5. Disconnect Bank Account
status2 = database.update_user_bank_connection("user_1001", None, is_connected=False)
print("✅ Disconnected Bank:", status2)

if __name__ == "__main__":
    pass
