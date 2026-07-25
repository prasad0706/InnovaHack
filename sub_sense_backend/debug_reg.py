import urllib.request
import urllib.error
import json

req = urllib.request.Request(
    'http://127.0.0.1:8000/api/auth/register',
    data=json.dumps({
        'email': 'prasadmahajan@gmail.com',
        'password': 'password123',
        'name': 'prasad mahajann'
    }).encode('utf-8'),
    headers={'Content-Type': 'application/json'}
)

try:
    res = urllib.request.urlopen(req)
    print("SUCCESS:", res.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("HTTP ERROR:", e.code, e.read().decode('utf-8'))
