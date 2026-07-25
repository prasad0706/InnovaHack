import sys
sys.stdout.reconfigure(encoding='utf-8')
import auth

print("=== TESTING SUPABASE LIVE AUTH ===")
try:
    res = auth.register_user("vedanthackathon@gmail.com", "SecretPass123!", "Vedant Hackathon")
    print("✅ Supabase Registration Success:", res)
except Exception as e:
    print("ℹ️ Note:", e)
