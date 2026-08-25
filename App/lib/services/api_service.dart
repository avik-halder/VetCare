import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/prediction.dart';
import '../models/sensor_data.dart';

class ApiService {
  // Update to your server address if needed
  static const String baseUrl = 'http://10.126.58.60:8000';

  // ---------- Auth token storage ----------
  static final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  static Future<void> _saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> logout() => _storage.delete(key: _tokenKey);

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  // ---------- Auth endpoints ----------
  /// POST /auth/register {name,email,password}
  static Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Signup failed (${res.statusCode})');
    }
  }

  /// POST /auth/login {email,password} -> {access_token}
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Login failed (${res.statusCode})');
    }
    final token = (jsonDecode(res.body)['access_token'] as String?);
    if (token == null) throw Exception('Token missing from response');
    await _saveToken(token);
  }

  /// GET /auth/me (optional helper)
  static Future<Map<String, dynamic>> me() async {
    final t = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $t'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 401) throw Exception('Unauthorized');
    throw Exception('Failed to load profile (${res.statusCode})');
  }

  // ---------- Helpers ----------
  static Future<http.Response> _authedGet(String path) async {
    final t = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $t'},
    );
    _check401(res);
    return res;
  }

  static void _check401(http.Response res) {
    if (res.statusCode == 401) {
      // Optionally: trigger a logout in UI when you catch this Exception.
      throw Exception('Unauthorized');
    }
  }

  static String? _extractError(String body) {
    try {
      final j = jsonDecode(body);
      return (j['detail'] ?? j['error'] ?? j['message'])?.toString();
    } catch (_) {
      return null;
    }
  }

  // ---------- Your existing features (now with auth) ----------
  /// POST /predict-image/ (protected) -> {prediction, confidence}
  static Future<String> predictFromImage(File imageFile) async {
    final t = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict-image/'),
    );
    request.headers['Authorization'] = 'Bearer $t';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamRes = await request.send();
    final res = await http.Response.fromStream(streamRes);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      // You can use 'prediction' or combine with confidence if you like
      return data['prediction']?.toString() ?? 'unknown';
    } else if (res.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Prediction failed (${res.statusCode})');
    }
  }

  /// GET /logs (protected) -> latest prediction logs
  static Future<List<Prediction>> getPredictionLogs() async {
    try {
      final response = await _authedGet('/logs');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Prediction.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load logs (${response.statusCode})');
      }
    } catch (e) {
      // You can handle 'Unauthorized' here by redirecting to Login
      // if (e.toString().contains('Unauthorized')) await logout();
      // and then navigate in UI
      return [];
    }
  }

  /// GET /sensor-latest (protected) -> last 10 sensor records
  static Future<List<SensorData>> getSensorDataLogs() async {
    try {
      final response = await _authedGet('/sensor-latest');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => SensorData.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load sensor logs (${response.statusCode})');
      }
    } catch (e) {
      return [];
    }
  }

  /// GET /predict-latest?explain=true&k=5 -> SHAP explanation + probs
  static Future<Map<String, dynamic>> getLatestHealthExplanation({int k = 3}) async {
    final res = await _authedGet('/predict-latest?explain=true&k=$k');
    if (res.statusCode != 200) {
      throw Exception('Health explanation failed (${res.statusCode})');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  /// GET /skin-latest -> latest lumpy/normal + timestamp
  static Future<Map<String, dynamic>> getSkinLatest() async {
    final res = await _authedGet('/skin-latest');
    if (res.statusCode != 200) {
      throw Exception('Skin status failed (${res.statusCode})');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }


  static Future getLatestSensorData() async {}
}
