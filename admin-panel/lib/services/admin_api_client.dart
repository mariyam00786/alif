import 'dart:convert';

import 'package:http/http.dart' as http;

class AdminApiClient {
  AdminApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _sessionToken;

  bool get isConfigured => _baseUrl.isNotEmpty && _activeToken.isNotEmpty;

  String get _baseUrl {
    final configured = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ).trim();
    final withoutTrailingSlash = configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;

    if (withoutTrailingSlash.endsWith('/api')) {
      return withoutTrailingSlash.substring(0, withoutTrailingSlash.length - 4);
    }

    return withoutTrailingSlash;
  }

  String get _accessToken => const String.fromEnvironment('ADMIN_ACCESS_TOKEN');
  String get _activeToken => _sessionToken?.trim().isNotEmpty == true
      ? _sessionToken!.trim()
      : _accessToken;

  void setAuthToken(String token) {
    _sessionToken = token.trim();
  }

  void clearAuthToken() {
    _sessionToken = null;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _client.get(_uri(path), headers: _headers);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.patch(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _client.delete(_uri(path), headers: _headers);
    return _decodeResponse(response);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_activeToken.isNotEmpty) 'Authorization': 'Bearer $_activeToken',
  };

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw StateError(
      decoded['error']?.toString() ??
          'Request failed with status ${response.statusCode}',
    );
  }
}
