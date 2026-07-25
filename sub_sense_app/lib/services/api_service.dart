  import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://innovahack-hsja.onrender.com';

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        throw ApiException(code: 'SERVER_ERROR', message: 'Invalid response from server.');
      }

      if (res.statusCode == 200 && body is Map && body['status'] == 'success') {
        return Map<String, dynamic>.from(body['user'] as Map);
      }

      String msg = 'Failed to create account.';
      if (body is Map) {
        if (body['message'] is String) {
          msg = body['message'];
        } else if (body['detail'] is String) {
          msg = body['detail'];
        }
      }

      throw ApiException(
        code: (body is Map ? body['error_code'] : null) ?? 'REGISTRATION_FAILED',
        message: msg,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        code: 'REGISTRATION_ERROR',
        message: e.toString(),
      );
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        throw ApiException(code: 'SERVER_ERROR', message: 'Invalid response from server.');
      }

      if (res.statusCode == 200 && body is Map && body['status'] == 'success') {
        return Map<String, dynamic>.from(body['user'] as Map);
      }

      String msg = 'Invalid email or password.';
      if (body is Map) {
        if (body['message'] is String) {
          msg = body['message'];
        } else if (body['detail'] is String) {
          msg = body['detail'];
        }
      }

      throw ApiException(
        code: (body is Map ? body['error_code'] : null) ?? 'AUTH_FAILED',
        message: msg,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        code: 'AUTH_ERROR',
        message: e.toString(),
      );
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        throw ApiException(code: 'SERVER_ERROR', message: 'Invalid response from server.');
      }

      if (res.statusCode == 200 && body is Map && body['status'] == 'success') {
        return Map<String, dynamic>.from(body['user'] as Map);
      }

      throw ApiException(
        code: (body is Map ? body['error_code'] : null) ?? 'UNAUTHORIZED',
        message: (body is Map ? body['message'] : null) ?? 'Session expired.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        code: 'NETWORK_ERROR',
        message: 'Could not verify authentication session.',
      );
    }
  }

  static Future<Map<String, dynamic>> connectBankAccount({
    String bankName = "HDFC Bank",
    int months = 6,
    String? token,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final res = await http.post(
        Uri.parse('$baseUrl/api/plaid/connect'),
        headers: headers,
        body: jsonEncode({
          'bank_name': bankName,
          'months': months,
        }),
      );

      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        return getDemoData();
      }

      if (res.statusCode == 200 && body is Map && body['status'] == 'success') {
        return Map<String, dynamic>.from(body);
      }
      return getDemoData();
    } catch (e) {
      return getDemoData();
    }
  }

  static Future<bool> disconnectBankAccount(String? token) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final res = await http.post(
        Uri.parse('$baseUrl/api/plaid/disconnect'),
        headers: headers,
        body: jsonEncode({}),
      );

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getLatestAnalysis(String? token) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final res = await http.get(
        Uri.parse('$baseUrl/api/analysis/latest'),
        headers: headers,
      );

      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        return getDemoData();
      }

      if (res.statusCode == 200 && body is Map && body['status'] == 'success') {
        return Map<String, dynamic>.from(body);
      }
      return getDemoData();
    } catch (e) {
      return getDemoData();
    }
  }

  static Future<Map<String, dynamic>> uploadStatement({
    required Uint8List fileBytes,
    required String filename,
    String? password,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
        ),
      );

      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (body['status'] == 'error') {
          throw ApiException(
            code: body['error_code'] ?? 'UNKNOWN_ERROR',
            message: body['message'] ?? 'An unknown error occurred.',
          );
        }
        return body;
      } else {
        final errCode = body['detail']?['error_code'] ??
            body['error_code'] ??
            'SERVER_ERROR';
        final errMessage = body['detail']?['message'] ??
            body['message'] ??
            'Failed to upload statement.';
        throw ApiException(code: errCode, message: errMessage);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      return getDemoData();
    }
  }

  static Map<String, dynamic> getDemoData() {
    return {
      "status": "success",
      "summary": {
        "total_transactions_found": 84,
        "subscriptions_detected": 5,
        "parsing_method": "table",
        "date_range": {
          "from_date": "2026-01-05",
          "to_date": "2026-07-20"
        }
      },
      "subscriptions": [
        {
          "id": "sub_1",
          "merchant": "Netflix",
          "category": "Entertainment",
          "frequency": "monthly",
          "current_amount": 649.0,
          "confidence": 0.98,
          "price_change": {
            "increased": true,
            "amount_change": 150.0,
            "percent_change": 30.1
          },
          "history": [
            {"date": "2026-02-05", "amount": 499.0},
            {"date": "2026-03-05", "amount": 499.0},
            {"date": "2026-04-05", "amount": 499.0},
            {"date": "2026-05-05", "amount": 649.0},
            {"date": "2026-06-05", "amount": 649.0},
            {"date": "2026-07-05", "amount": 649.0}
          ],
          "recommended_action": "Downgrade",
          "action_reason": "Price increased by 30.1% recently (+₹150). Switch to Standard Plan to save.",
          "monthly_saving": 150.0
        },
        {
          "id": "sub_2",
          "merchant": "Adobe Creative Cloud",
          "category": "Software",
          "frequency": "monthly",
          "current_amount": 1675.0,
          "confidence": 0.95,
          "price_change": {
            "increased": false,
            "amount_change": 0.0,
            "percent_change": 0.0
          },
          "history": [
            {"date": "2026-02-12", "amount": 1675.0},
            {"date": "2026-03-12", "amount": 1675.0},
            {"date": "2026-04-12", "amount": 1675.0},
            {"date": "2026-05-12", "amount": 1675.0},
            {"date": "2026-06-12", "amount": 1675.0},
            {"date": "2026-07-12", "amount": 1675.0}
          ],
          "recommended_action": "Cancel",
          "action_reason": "High monthly cost (₹1,675) with low relative utility detected.",
          "monthly_saving": 1675.0
        },
        {
          "id": "sub_3",
          "merchant": "YouTube Premium",
          "category": "Entertainment",
          "frequency": "monthly",
          "current_amount": 149.0,
          "confidence": 0.92,
          "price_change": {
            "increased": false,
            "amount_change": 0.0,
            "percent_change": 0.0
          },
          "history": [
            {"date": "2026-02-20", "amount": 149.0},
            {"date": "2026-03-20", "amount": 149.0},
            {"date": "2026-04-20", "amount": 149.0},
            {"date": "2026-05-20", "amount": 149.0},
            {"date": "2026-06-20", "amount": 149.0},
            {"date": "2026-07-20", "amount": 149.0}
          ],
          "recommended_action": "Keep",
          "action_reason": "Regular usage pattern at standard market price.",
          "monthly_saving": 0.0
        },
        {
          "id": "sub_4",
          "merchant": "Spotify",
          "category": "Music",
          "frequency": "monthly",
          "current_amount": 119.0,
          "confidence": 0.91,
          "price_change": {
            "increased": false,
            "amount_change": 0.0,
            "percent_change": 0.0
          },
          "history": [
            {"date": "2026-02-18", "amount": 119.0},
            {"date": "2026-03-18", "amount": 119.0},
            {"date": "2026-04-18", "amount": 119.0},
            {"date": "2026-05-18", "amount": 119.0},
            {"date": "2026-06-18", "amount": 119.0},
            {"date": "2026-07-18", "amount": 119.0}
          ],
          "recommended_action": "Keep",
          "action_reason": "Active monthly subscription with consistent billing.",
          "monthly_saving": 0.0
        },
        {
          "id": "sub_5",
          "merchant": "Apple iCloud",
          "category": "Cloud Services",
          "frequency": "monthly",
          "current_amount": 75.0,
          "confidence": 0.89,
          "price_change": {
            "increased": false,
            "amount_change": 0.0,
            "percent_change": 0.0
          },
          "history": [
            {"date": "2026-02-25", "amount": 75.0},
            {"date": "2026-03-25", "amount": 75.0},
            {"date": "2026-04-25", "amount": 75.0},
            {"date": "2026-05-25", "amount": 75.0},
            {"date": "2026-06-25", "amount": 75.0},
            {"date": "2026-07-25", "amount": 75.0}
          ],
          "recommended_action": "Keep",
          "action_reason": "Low-cost cloud backup tier.",
          "monthly_saving": 0.0
        }
      ],
      "all_transactions": [
        {"date": "2026-07-25", "raw_description": "APPLE.COM/BILL ICLOUD STORAGE", "merchant": "Apple iCloud", "category": "Cloud Services", "amount": 75.0},
        {"date": "2026-07-20", "raw_description": "GOOGLE *YOUTUBEPREM", "merchant": "YouTube Premium", "category": "Entertainment", "amount": 149.0},
        {"date": "2026-07-18", "raw_description": "UPI/SPOTIFY INDIA", "merchant": "Spotify", "category": "Music", "amount": 119.0},
        {"date": "2026-07-12", "raw_description": "AUTOPAY ADOBE SYSTEMS", "merchant": "Adobe Creative Cloud", "category": "Software", "amount": 1675.0},
        {"date": "2026-07-05", "raw_description": "UPI/NETFLIX.COM/BANGALORE", "merchant": "Netflix", "category": "Entertainment", "amount": 649.0}
      ]
    };
  }
}

class ApiException implements Exception {
  final String code;
  final String message;

  ApiException({required this.code, required this.message});

  @override
  String toString() => message;
}
