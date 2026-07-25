import os
import json
import uuid
import datetime
from typing import Optional, Dict, Any, List
from dotenv import load_dotenv

load_dotenv(override=True)

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
ANALYSES_FILE = os.path.join(DATA_DIR, "analyses.json")
USERS_FILE = os.path.join(DATA_DIR, "users.json")

_supabase_client = None

def get_supabase_client():
    global _supabase_client
    if _supabase_client is not None:
        return _supabase_client

    load_dotenv(override=True)
    supabase_url = os.getenv("SUPABASE_URL", "").strip()
    supabase_key = os.getenv("SUPABASE_KEY", "").strip()

    if supabase_url and supabase_key:
        try:
            from supabase import create_client
            _supabase_client = create_client(supabase_url, supabase_key)
            print(f"Connected to Supabase PostgreSQL Database! ({supabase_url})")
            return _supabase_client
        except Exception as e:
            print(f"Supabase connection notice: {e}")
            return None
    return None

def _load_local_analyses() -> Dict[str, Any]:
    os.makedirs(DATA_DIR, exist_ok=True)
    if os.path.exists(ANALYSES_FILE):
        try:
            with open(ANALYSES_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def _save_local_analyses(data: Dict[str, Any]):
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(ANALYSES_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

def update_user_bank_connection(user_id: str, bank_name: Optional[str], is_connected: bool) -> Dict[str, Any]:
    now_str = datetime.datetime.now(datetime.timezone.utc).isoformat() if is_connected else None

    sb = get_supabase_client()
    if sb is not None:
        try:
            sb.auth.admin.update_user_by_id(user_id, {
                "user_metadata": {
                    "is_bank_connected": is_connected,
                    "connected_bank": bank_name if is_connected else None,
                    "bank_connected_at": now_str
                }
            })
        except Exception as e:
            print(f"Supabase update bank connection notice: {e}")

    if os.path.exists(USERS_FILE):
        try:
            with open(USERS_FILE, "r", encoding="utf-8") as f:
                users = json.load(f)
            
            for email, u in users.items():
                if u.get("id") == user_id:
                    u["is_bank_connected"] = is_connected
                    u["connected_bank"] = bank_name if is_connected else None
                    u["bank_connected_at"] = now_str
                    break
            with open(USERS_FILE, "w", encoding="utf-8") as f:
                json.dump(users, f, indent=2)
        except Exception as e:
            print(f"Local users.json update notice: {e}")

    return {
        "user_id": user_id,
        "is_bank_connected": is_connected,
        "connected_bank": bank_name if is_connected else None,
        "bank_connected_at": now_str
    }

def merge_and_save_analysis(
    user_id: str,
    summary: Dict[str, Any],
    subscriptions: List[Dict[str, Any]],
    new_transactions: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Merges statement/bank entries with existing transaction history,
    STRICTLY deduplicates by (date, amount, merchant/description),
    and sorts chronologically by date descending.
    """
    existing = get_latest_analysis(user_id)
    existing_txns = existing.get("all_transactions", []) if existing else []

    # Strict transaction deduplication
    txn_map = {}
    for t in existing_txns + new_transactions:
        date_val = str(t.get("date", "")).strip()
        amt_val = f"{float(t.get('amount', 0)):.2f}"
        merchant_val = (t.get("merchant") or t.get("raw_description") or "").strip().lower()
        
        # Deduplication key
        key = f"{date_val}_{amt_val}_{merchant_val}"
        
        if key not in txn_map:
            txn_map[key] = t
        else:
            # Prefer transaction item with cleaner merchant name
            if len(t.get("merchant", "")) > len(txn_map[key].get("merchant", "")):
                txn_map[key] = t

    all_txns = list(txn_map.values())
    all_txns.sort(key=lambda x: str(x.get("date", "2026-01-01")), reverse=True)

    # Deduplicate subscriptions by merchant name
    sub_map = {}
    for s in subscriptions:
        m_key = s.get("merchant", "").strip().lower()
        if m_key and m_key not in sub_map:
            sub_map[m_key] = s
    unique_subs = list(sub_map.values())

    analysis_id = str(uuid.uuid4())
    payload = {
        "analysis_id": analysis_id,
        "user_id": user_id,
        "summary": summary,
        "subscriptions": unique_subs,
        "all_transactions": all_txns,
    }

    sb = get_supabase_client()
    if sb is not None:
        try:
            sb.table("statement_analyses").upsert({
                "id": analysis_id,
                "user_id": user_id,
                "summary": summary,
                "subscriptions": unique_subs,
                "all_transactions": all_txns,
            }).execute()
        except Exception as e:
            print(f"Supabase table insert notice: {e}")

    local_db = _load_local_analyses()
    local_db[user_id] = payload
    _save_local_analyses(local_db)

    return payload

def save_analysis(
    user_id: str,
    summary: Dict[str, Any],
    subscriptions: List[Dict[str, Any]],
    all_transactions: List[Dict[str, Any]],
) -> Dict[str, Any]:
    return merge_and_save_analysis(user_id, summary, subscriptions, all_transactions)

def get_latest_analysis(user_id: str) -> Optional[Dict[str, Any]]:
    sb = get_supabase_client()
    if sb is not None:
        try:
            res = sb.table("statement_analyses").select("*").eq("user_id", user_id).order("created_at", desc=True).limit(1).execute()
            if res.data and len(res.data) > 0:
                item = res.data[0]
                return {
                    "status": "success",
                    "summary": item.get("summary", {}),
                    "subscriptions": item.get("subscriptions", []),
                    "all_transactions": item.get("all_transactions", []),
                }
        except Exception as e:
            print(f"Supabase fetch notice: {e}")

    local_db = _load_local_analyses()
    if user_id in local_db:
        item = local_db[user_id]
        return {
            "status": "success",
            "summary": item.get("summary", {}),
            "subscriptions": item.get("subscriptions", []),
            "all_transactions": item.get("all_transactions", []),
        }

    if "default_user" in local_db:
        item = local_db["default_user"]
        return {
            "status": "success",
            "summary": item.get("summary", {}),
            "subscriptions": item.get("subscriptions", []),
            "all_transactions": item.get("all_transactions", []),
        }

    return None
