import sys
sys.stdout.reconfigure(encoding='utf-8')
import database

print("=== TESTING DATABASE STATEMENT PERSISTENCE ===")

sample_summary = {
    "total_transactions_found": 35,
    "subscriptions_detected": 4,
    "parsing_method": "table",
    "date_range": {"from_date": "2026-02-01", "to_date": "2026-07-25"},
    "health_score": 82
}

sample_subs = [
    {"id": "sub_101", "merchant": "Netflix", "category": "Entertainment", "current_amount": 649.0, "recommended_action": "Downgrade", "monthly_saving": 150.0},
    {"id": "sub_102", "merchant": "Spotify", "category": "Music", "current_amount": 119.0, "recommended_action": "Keep", "monthly_saving": 0.0}
]

sample_txns = [
    {"date": "2026-07-25", "raw_description": "UPI/NETFLIX.COM/BANGALORE", "merchant": "Netflix", "category": "Entertainment", "amount": 649.0},
    {"date": "2026-07-18", "raw_description": "UPI/SPOTIFY INDIA", "merchant": "Spotify", "category": "Music", "amount": 119.0}
]

# 1. Save analysis to Database
saved = database.save_analysis("vedanthackathon@gmail.com", sample_summary, sample_subs, sample_txns)
print("✅ Saved to DB:", saved["analysis_id"])

# 2. Fetch latest analysis from Database
fetched = database.get_latest_analysis("vedanthackathon@gmail.com")
print("✅ Fetched from DB:")
print("   - Subscriptions:", len(fetched["subscriptions"]))
print("   - Transactions Ledger:", len(fetched["all_transactions"]))

if __name__ == "__main__":
    pass
