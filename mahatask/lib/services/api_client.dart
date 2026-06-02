import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session_store.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String get defaultBaseUrl {
    const backendPort = '3001';
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:$backendPort';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$backendPort';
      default:
        return 'http://localhost:$backendPort';
    }
  }

  String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultBaseUrl;
  }

  Future<dynamic> get(String endpoint, {bool authenticated = true}) async {
    final response = await _send(
      () => _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(authenticated: authenticated),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _send(
      () => _client.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> delete(String endpoint, {bool authenticated = true}) async {
    final response = await _send(
      () => _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(authenticated: authenticated),
      ),
    );
    return _decode(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } catch (_) {
      throw Exception(
        'Tidak bisa terhubung ke backend di $baseUrl. Pastikan saku-backend berjalan di port 3001.',
      );
    }
  }

  Map<String, String> _headers({required bool authenticated}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (!authenticated) return headers;

    final token = SessionStore.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Session login tidak ditemukan. Silakan login ulang.');
    }
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception(_message(response.body));
  }

  String _message(String body) {
    if (body.isEmpty) return 'Request gagal. Coba lagi.';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return _friendlyMessage(message);
        }
        if (message is List && message.isNotEmpty) {
          return _friendlyMessage(message.first.toString());
        }
      }
    } catch (_) {}
    return 'Request gagal. Coba lagi.';
  }

  String _friendlyMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('prisma') ||
        normalized.contains('database server') ||
        normalized.contains('can\'t reach database') ||
        normalized.contains('invocation in')) {
      return 'Backend berjalan, tapi database belum bisa diakses. Periksa koneksi Supabase dan DATABASE_URL.';
    }
    return message;
  }
}
