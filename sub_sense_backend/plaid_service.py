import os
import datetime
from typing import Optional, Dict, Any, List
from dotenv import load_dotenv

load_dotenv(override=True)

PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID", "").strip()
PLAID_SECRET = os.getenv("PLAID_SECRET", "").strip()
PLAID_ENV = os.getenv("PLAID_ENV", "sandbox").strip().lower()

_plaid_client = None

def get_plaid_client():
    global _plaid_client
    if _plaid_client is not None:
        return _plaid_client

    if PLAID_CLIENT_ID and PLAID_SECRET:
        try:
            import plaid
            from plaid.api import plaid_api
            from plaid.configuration import Configuration
            from plaid.api_client import ApiClient

            host_map = {
                "sandbox": plaid.Environment.Sandbox,
                "development": plaid.Environment.Development,
                "production": plaid.Environment.Production,
            }
            host = host_map.get(PLAID_ENV, plaid.Environment.Sandbox)

            configuration = Configuration(
                host=host,
                api_key={
                    'clientId': PLAID_CLIENT_ID,
                    'secret': PLAID_SECRET,
                }
            )
            api_client = ApiClient(configuration)
            _plaid_client = plaid_api.PlaidApi(api_client)
            print(f"✅ Plaid API client initialized in {PLAID_ENV} mode!")
            return _plaid_client
        except Exception as e:
            print(f"Plaid client initialization notice: {e}")
            return None
    return None

def create_link_token(user_id: str) -> Dict[str, Any]:
    client = get_plaid_client()
    if client is not None:
        try:
            from plaid.model.link_token_create_request import LinkTokenCreateRequest
            from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
            from plaid.model.products import Products
            from plaid.model.country_code import CountryCode

            request = LinkTokenCreateRequest(
                products=[Products('transactions')],
                client_name="SubSense Leak Detector",
                country_codes=[CountryCode('US')],
                language='en',
                user=LinkTokenCreateRequestUser(client_user_id=user_id)
            )
            response = client.link_token_create(request)
            return {
                "status": "success",
                "link_token": response['link_token'],
                "mode": PLAID_ENV,
            }
        except Exception as e:
            print(f"Plaid link_token_create error: {e}")

    return {
        "status": "success",
        "link_token": f"link-sandbox-subsense-{user_id[:8]}",
        "mode": "sandbox_demo",
    }

def exchange_public_token(public_token: str) -> Dict[str, Any]:
    client = get_plaid_client()
    if client is not None:
        try:
            from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
            request = ItemPublicTokenExchangeRequest(public_token=public_token)
            response = client.item_public_token_exchange(request)
            return {
                "status": "success",
                "access_token": response['access_token'],
                "item_id": response['item_id'],
            }
        except Exception as e:
            print(f"Plaid token exchange error: {e}")

    return {
        "status": "success",
        "access_token": "access-sandbox-subsense-demo-token",
        "item_id": "item-sandbox-subsense-demo-id",
    }

def fetch_bank_transactions(bank_name: str = "HDFC Bank", months: int = 6) -> List[Dict[str, Any]]:
    """
    Fetches raw transactions from Plaid Sandbox (or Sandbox Bank Generator)
    and normalizes them into the exact structure expected by clean_transactions()
    and subscription_detector.py.
    """
    client = get_plaid_client()
    if client is not None:
        try:
            from plaid.model.transactions_get_request import TransactionsGetRequest
            from plaid.model.transactions_get_request_options import TransactionsGetRequestOptions
            
            start_date = datetime.date.today() - datetime.timedelta(days=months * 30)
            end_date = datetime.date.today()
            request = TransactionsGetRequest(
                access_token="access-sandbox-subsense-demo-token",
                start_date=start_date,
                end_date=end_date,
                options=TransactionsGetRequestOptions(count=500)
            )
            response = client.transactions_get(request)
            raw_plaid_txns = response['transactions']
            
            normalized = []
            for t in raw_plaid_txns:
                amount = float(t['amount'])
                if amount > 0:
                    normalized.append({
                        "date": str(t['date']),
                        "raw_description": t.get('name') or t.get('original_description') or 'Plaid Merchant',
                        "merchant": t.get('merchant_name') or t.get('name') or 'General',
                        "category": t.get('category', ['General'])[0] if t.get('category') else 'General',
                        "amount": str(amount),
                        "type": "debit"
                    })
            if len(normalized) > 5:
                return normalized
        except Exception as e:
            print(f"Plaid transactions_get notice: {e}")

    txns = []
    today = datetime.date.today()

    recurring_merchants = [
        {"merchant": "Netflix", "raw": f"UPI/NETFLIX.COM/{bank_name.upper()}", "base_amount": 499.0, "hike_month": 4, "hike_amount": 649.0, "category": "Entertainment"},
        {"merchant": "Adobe Creative Cloud", "raw": f"AUTOPAY ADOBE SYSTEMS {bank_name.upper()}", "base_amount": 1675.0, "hike_month": -1, "hike_amount": 1675.0, "category": "Software"},
        {"merchant": "YouTube Premium", "raw": f"GOOGLE *YOUTUBEPREM {bank_name.upper()}", "base_amount": 149.0, "hike_month": -1, "hike_amount": 149.0, "category": "Entertainment"},
        {"merchant": "Spotify", "raw": f"UPI/SPOTIFY INDIA {bank_name.upper()}", "base_amount": 119.0, "hike_month": -1, "hike_amount": 119.0, "category": "Music"},
        {"merchant": "Apple iCloud", "raw": f"APPLE.COM/BILL ICLOUD {bank_name.upper()}", "base_amount": 75.0, "hike_month": -1, "hike_amount": 75.0, "category": "Cloud Services"},
        {"merchant": "Swiggy One", "raw": f"SWIGGY ONE MEMBERSHIP {bank_name.upper()}", "base_amount": 299.0, "hike_month": -1, "hike_amount": 299.0, "category": "Food"},
        {"merchant": "Cult.fit", "raw": f"CULTFIT HEALTHCARE {bank_name.upper()}", "base_amount": 1250.0, "hike_month": -1, "hike_amount": 1250.0, "category": "Fitness"},
    ]

    for m in range(months - 1, -1, -1):
        month_date = today - datetime.timedelta(days=m * 30)

        for item in recurring_merchants:
            amt = item["hike_amount"] if (item["hike_month"] != -1 and m < item["hike_month"]) else item["base_amount"]
            day_offset = (hash(item["merchant"]) % 20) + 1
            txn_date = datetime.date(month_date.year, month_date.month, min(day_offset, 28))

            txns.append({
                "date": txn_date.strftime("%Y-%m-%d"),
                "raw_description": item["raw"],
                "merchant": item["merchant"],
                "category": item["category"],
                "amount": str(amt),
                "type": "debit"
            })

    txns.sort(key=lambda x: x["date"], reverse=True)
    return txns
