import os
import json
import hashlib
import uuid
import secrets
from typing import Optional, Dict, Any
import database

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
USERS_FILE = os.path.join(DATA_DIR, "users.json")

def _load_users_db() -> Dict[str, Any]:
    os.makedirs(DATA_DIR, exist_ok=True)
    if os.path.exists(USERS_FILE):
        try:
            with open(USERS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def _save_users_db(users: Dict[str, Any]):
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(USERS_FILE, "w", encoding="utf-8") as f:
        json.dump(users, f, indent=2)

def hash_password(password: str, salt: Optional[str] = None) -> tuple[str, str]:
    if not salt:
        salt = secrets.token_hex(16)
    salted = (password + salt).encode('utf-8')
    pw_hash = hashlib.sha256(salted).hexdigest()
    return pw_hash, salt

def register_user(email: str, password: str, name: str) -> Dict[str, Any]:
    email_clean = email.strip().lower()
    if not email_clean or "@" not in email_clean:
        raise ValueError("Invalid email address format.")
    if len(password) < 6:
        raise ValueError("Password must be at least 6 characters long.")

    sb = database.get_supabase_client()
    if sb is not None:
        try:
            res = sb.auth.sign_up({"email": email_clean, "password": password, "options": {"data": {"name": name}}})
            if res.user:
                # Also save to local users.json for fast sync
                user_id = res.user.id
                token = res.session.access_token if res.session else secrets.token_urlsafe(32)
                pw_hash, salt = hash_password(password)
                users = _load_users_db()
                users[email_clean] = {
                    "id": user_id,
                    "email": email_clean,
                    "name": name or email_clean.split("@")[0].title(),
                    "password_hash": pw_hash,
                    "salt": salt,
                    "token": token,
                }
                _save_users_db(users)
                return {
                    "id": user_id,
                    "email": email_clean,
                    "name": name or email_clean.split("@")[0].title(),
                    "token": token,
                }
        except Exception as e:
            err_str = str(e)
            if "rate limit" in err_str.lower():
                raise ValueError("Supabase Email Rate Limit exceeded. Please disable 'Confirm Email' in your Supabase Auth settings.")
            elif "already registered" in err_str.lower() or "already exists" in err_str.lower():
                raise ValueError("An account with this email address already exists.")
            else:
                print(f"Supabase auth notice: {e}")

    users = _load_users_db()
    if email_clean in users:
        raise ValueError("An account with this email address already exists.")

    pw_hash, salt = hash_password(password)
    user_id = str(uuid.uuid4())
    token = secrets.token_urlsafe(32)

    user_entry = {
        "id": user_id,
        "email": email_clean,
        "name": name.strip() if name else email_clean.split("@")[0].title(),
        "password_hash": pw_hash,
        "salt": salt,
        "token": token,
    }

    users[email_clean] = user_entry
    _save_users_db(users)

    return {
        "id": user_id,
        "email": email_clean,
        "name": user_entry["name"],
        "token": token,
    }

def login_user(email: str, password: str) -> Dict[str, Any]:
    email_clean = email.strip().lower()

    sb = database.get_supabase_client()
    if sb is not None:
        try:
            res = sb.auth.sign_in_with_password({"email": email_clean, "password": password})
            if res.user:
                token = res.session.access_token if res.session else secrets.token_urlsafe(32)
                return {
                    "id": res.user.id,
                    "email": email_clean,
                    "name": res.user.user_metadata.get("name", email_clean.split("@")[0].title()),
                    "token": token,
                }
        except Exception as e:
            print(f"Supabase auth login notice: {e}")

    users = _load_users_db()
    if email_clean not in users:
        raise ValueError("No account found with this email address.")

    user_entry = users[email_clean]
    pw_hash, _ = hash_password(password, user_entry["salt"])

    if pw_hash != user_entry["password_hash"]:
        raise ValueError("Incorrect password. Please try again.")

    token = secrets.token_urlsafe(32)
    user_entry["token"] = token
    users[email_clean] = user_entry
    _save_users_db(users)

    return {
        "id": user_entry["id"],
        "email": email_clean,
        "name": user_entry["name"],
        "token": token,
    }

def verify_token(token: str) -> Optional[Dict[str, Any]]:
    if not token:
        return None

    sb = database.get_supabase_client()
    if sb is not None:
        try:
            user = sb.auth.get_user(token)
            if user and user.user:
                return {
                    "id": user.user.id,
                    "email": user.user.email,
                    "name": user.user.user_metadata.get("name", user.user.email.split("@")[0].title()),
                    "token": token,
                }
        except Exception:
            pass

    users = _load_users_db()
    for email, user in users.items():
        if user.get("token") == token:
            return {
                "id": user["id"],
                "email": user["email"],
                "name": user["name"],
                "token": token,
            }
    return None
