import sys
sys.stdout.reconfigure(encoding='utf-8')
import json
import os
from dotenv import load_dotenv

load_dotenv(override=True)

from supabase import create_client

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")

print(f"Connecting to Supabase: {url}")
sb = create_client(url, key)

with open("data/users.json", "r", encoding="utf-8") as f:
    users = json.load(f)

for email, user in users.items():
    name = user.get("name", "")
    print(f"Syncing user: {email} ({name})...")
    try:
        res = sb.auth.sign_up({
            "email": email,
            "password": "password123", # standard default password for synced accounts
            "options": {"data": {"name": name}}
        })
        if res.user:
            print(f"  ✅ Synced: {email} -> ID: {res.user.id}")
        else:
            print(f"  ℹ️ Notice: {email}")
    except Exception as e:
        print(f"  ℹ️ Status for {email}: {e}")

print("=== SYNC COMPLETE ===")
