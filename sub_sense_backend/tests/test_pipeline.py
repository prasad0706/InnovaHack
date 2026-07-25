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

if __name__ == "__main__":
    unittest.main()
