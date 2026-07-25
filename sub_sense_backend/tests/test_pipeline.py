import unittest
from cleaning.transaction_cleaner import clean_transactions, parse_date, parse_amount
from cleaning.merchant_normalizer import strip_noise, normalize_merchant
from detection.price_checker import detect_price_increase
from detection.subscription_detector import detect_subscriptions

class TestSubSensePipeline(unittest.TestCase):

    def test_noise_stripping(self):
        desc = "UPI/123456789/NETFLIX.COM/BANGALORE"
        cleaned = strip_noise(desc)
        self.assertNotIn("UPI", cleaned)
        self.assertNotIn("123456789", cleaned)

    def test_merchant_normalization(self):
        norm = normalize_merchant("GOOGLE *YOUTUBEPREM")
        self.assertEqual(norm["canonical"], "YouTube Premium")

    def test_price_increase_detection(self):
        history = [
            {"date": "2026-04-01", "amount": 499.0},
            {"date": "2026-05-01", "amount": 499.0},
            {"date": "2026-06-01", "amount": 649.0},
        ]
        res = detect_price_increase(history)
        self.assertTrue(res["increased"])
        self.assertEqual(res["amount_change"], 150.0)
        self.assertAlmostEqual(res["percent_change"], 30.1, places=1)

    def test_subscription_detection(self):
        txns = [
            {"date": "2026-04-05", "raw_description": "NETFLIX", "merchant": "Netflix", "category": "Entertainment", "amount": 499.0},
            {"date": "2026-05-05", "raw_description": "NETFLIX", "merchant": "Netflix", "category": "Entertainment", "amount": 499.0},
            {"date": "2026-06-05", "raw_description": "NETFLIX", "merchant": "Netflix", "category": "Entertainment", "amount": 649.0},
        ]
        subs = detect_subscriptions(txns)
        self.assertEqual(len(subs), 1)
        self.assertEqual(subs[0]["merchant"], "Netflix")
        self.assertEqual(subs[0]["recommended_action"], "Downgrade")

    def test_health_score_calculation(self):
        from detection.subscription_detector import calculate_health_score
        
        # Test clean subscriptions (no leakage, no price hikes, no duplicates, no high-cost)
        subs = [
            {"current_amount": 199.0, "recommended_action": "Keep", "category": "Music", "price_change": {"increased": False}},
            {"current_amount": 299.0, "recommended_action": "Keep", "category": "Cloud Services", "price_change": {"increased": False}},
        ]
        score = calculate_health_score(subs)
        # Expected: no penalties. 100 clamped to 98
        self.assertEqual(score, 98)

        # Test leakage, price hikes, duplicate and high-cost cancel
        subs_with_leaks = [
            # Leakage ratio: 649 / (199+299+649) = 56.6%. Leak penalty: 56.6% * 50 = 28.3 points.
            # Price hike detected: -5 points.
            # Category Entertainment has 1 sub, Music has 1 sub, Cloud has 1 sub. No duplicate categories.
            # Action is Cancel, current_amount is 649 (> 500): high-cost penalty -5 points.
            # Total deductions: 28.3 + 5 + 5 = 38.3. Score: 100 - 38.3 = 61.7 -> round to 62
            {"current_amount": 199.0, "recommended_action": "Keep", "category": "Music", "price_change": {"increased": False}},
            {"current_amount": 299.0, "recommended_action": "Keep", "category": "Cloud Services", "price_change": {"increased": False}},
            {"current_amount": 649.0, "recommended_action": "Cancel", "category": "Entertainment", "price_change": {"increased": True, "amount_change": 150.0, "percent_change": 30.1}},
        ]
        score_leaks = calculate_health_score(subs_with_leaks)
        self.assertEqual(score_leaks, 62)

if __name__ == "__main__":
    unittest.main()
