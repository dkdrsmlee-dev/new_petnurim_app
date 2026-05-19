import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_envelope.dart';
import 'api_exception.dart';

class ApiClient {
  const ApiClient({required AppConfig config, required http.Client httpClient})
    : _config = config,
      _httpClient = httpClient;

  final AppConfig _config;
  final http.Client _httpClient;

  Uri uri(String path) => _config.apiUri(path);

  Future<Object?> getJson(
    String path, {
    Map<String, String>? headers,
    String? bearerToken,
    String fallbackMessage = '요청 처리에 실패했습니다.',
  }) {
    return _requestJson(
      method: 'GET',
      path: path,
      headers: headers,
      bearerToken: bearerToken,
      fallbackMessage: fallbackMessage,
    );
  }

  Future<Object?> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    String? bearerToken,
    String fallbackMessage = '요청 처리에 실패했습니다.',
  }) {
    return _requestJson(
      method: 'POST',
      path: path,
      body: body,
      headers: headers,
      bearerToken: bearerToken,
      fallbackMessage: fallbackMessage,
    );
  }

  Future<Object?> patchJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    String? bearerToken,
    String fallbackMessage = '요청 처리에 실패했습니다.',
  }) {
    return _requestJson(
      method: 'PATCH',
      path: path,
      body: body,
      headers: headers,
      bearerToken: bearerToken,
      fallbackMessage: fallbackMessage,
    );
  }

  Future<Object?> _requestJson({
    required String method,
    required String path,
    Object? body,
    Map<String, String>? headers,
    String? bearerToken,
    required String fallbackMessage,
  }) async {
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (bearerToken != null && bearerToken.trim().isNotEmpty)
        'Authorization': 'Bearer ${bearerToken.trim()}',
      ...?headers,
    };

    final encodedBody = body == null ? null : jsonEncode(body);
    final response = await _send(
      method: method,
      uri: uri(path),
      headers: requestHeaders,
      body: encodedBody,
    );
    final payload = _decodeJson(response.body, fallbackMessage);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        extractEnvelopeMessage(payload, fallbackMessage),
        statusCode: response.statusCode,
      );
    }

    ensureEnvelopeSuccess(payload, fallbackMessage);
    return unwrapEnvelopeData(payload);
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    switch (method) {
      case 'GET':
        return _httpClient.get(uri, headers: headers);
      case 'POST':
        return _httpClient.post(uri, headers: headers, body: body);
      case 'PATCH':
        return _httpClient.patch(uri, headers: headers, body: body);
      default:
        throw ArgumentError.value(method, 'method', '지원하지 않는 HTTP 메서드입니다.');
    }
  }

  Object? _decodeJson(String responseBody, String fallbackMessage) {
    if (responseBody.trim().isEmpty) {
      return <String, Object?>{};
    }

    try {
      return jsonDecode(responseBody);
    } on FormatException {
      throw ApiException('응답 형식이 올바르지 않습니다. $fallbackMessage');
    }
  }
}

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    httpClient: ref.watch(httpClientProvider),
  );
});
