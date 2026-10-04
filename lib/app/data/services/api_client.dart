import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';

/// Galat dari API: [status] 0 = tidak bisa terhubung ke server.
class ApiException implements Exception {
  final int status;
  final dynamic data;

  const ApiException(this.status, [this.data]);

  bool get isUnauthorized => status == 401;

  /// Nilai `error` dari body JSON (mis. "price_changed" atau pesan galat server).
  String? get error {
    final d = data;
    if (d is Map && d['error'] is String) return d['error'] as String;
    return null;
  }

  @override
  String toString() => 'ApiException($status, $error)';
}

/// Pesan galat ramah untuk ditampilkan (sama dengan errorMessage di mihan-store-web).
String apiErrorMessage(Object err, String fallback) {
  if (err is ApiException) {
    final e = err.error;
    if (e != null && e.isNotEmpty) return e;
    if (err.status == 429) return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
    if (err.status == 413) return 'Data yang dikirim terlalu besar.';
    if (err.status == 0) return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
  }
  return fallback;
}

/// Klien HTTP JSON bersama. Token sesi dikirim lewat header Authorization; jangan pernah dicetak ke log.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Diisi AuthController: token sesi yang sedang aktif (hanya di memori).
  static String? Function()? tokenProvider;

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: ApiConfig.timeoutDuration);

  Future<dynamic> get(String path, {bool auth = true}) => _send('GET', path, auth: auth);
  Future<dynamic> post(String path, [Object? body, bool auth = true]) =>
      _send('POST', path, body: body, auth: auth);
  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body, bool auth = true}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      final req = await _client.openUrl(method, uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final token = auth ? tokenProvider?.call() : null;
      if (token != null && token.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(jsonEncode(body)));
      }
      final res = await req.close().timeout(const Duration(seconds: ApiConfig.timeoutDuration));
      final text = await res.transform(utf8.decoder).join();
      dynamic data;
      if (text.isNotEmpty) {
        try {
          data = jsonDecode(text);
        } on FormatException {
          data = null;
        }
      }
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      throw ApiException(res.statusCode, data);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(0);
    } on TimeoutException {
      throw const ApiException(0);
    } on HttpException {
      throw const ApiException(0);
    }
  }
}

int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

int? asIntOrNull(dynamic v) => v == null ? null : asInt(v);

String asStr(dynamic v) => v?.toString() ?? '';

String? asStrOrNull(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}
