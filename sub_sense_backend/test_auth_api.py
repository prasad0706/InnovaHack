import sys
sys.stdout.reconfigure(encoding='utf-8')
import auth

def test_auth():
    print("=== TESTING LIGHTWEIGHT AUTH MODULE ===")

    # 1. Register user
    try:
        user1 = auth.register_user("testuser@subsense.app", "secret123", "Test User")
        print("✅ Registration successful:", user1)
    except ValueError as e:
        print("ℹ️ Note:", e)

    # 2. Login user
    try:
        user2 = auth.login_user("testuser@subsense.app", "secret123")
        print("✅ Login successful:", user2)
    except ValueError as e:
        print("❌ Login failed:", e)

    # 3. Verify token
    token = user2.get("token")
    verified = auth.verify_token(token)
    print("✅ Token verification:", verified)

if __name__ == "__main__":
    test_auth()
