import sys
sys.stdout.reconfigure(encoding='utf-8')
import plaid_service
from cleaning.transaction_cleaner import clean_transactions
from cleaning.merchant_normalizer import normalize_transactions
from detection.subscription_detector import detect_subscriptions, calculate_health_score

print("=== TESTING PLAID BANK CONNECT PIPELINE ===")

raw = plaid_service.fetch_bank_transactions("HDFC Bank", months=6)
cleaned = clean_transactions(raw)
normalized = normalize_transactions(cleaned)
subs = detect_subscriptions(normalized)
score = calculate_health_score(subs)

print(f"✅ Cleaned txns count: {len(cleaned)}")
print(f"✅ Normalized sample: {normalized[0]}")
print(f"✅ Detected {len(subs)} Recurring Subscriptions")
print(f"✅ Calculated Health Score: {score}")

for s in subs:
    print(f"   - {s['merchant']} ({s['category']}): ₹{s['current_amount']} -> Action: {s['recommended_action']}")

if __name__ == "__main__":
    pass
