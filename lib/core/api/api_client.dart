import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_envelope.dart';
import 'api_exception.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ApiClient {
  ApiClient({
    required AppConfig config,
    required http.Client httpClient,
    this.tokenStorage,
    this.onUnauthorized,
    this.onTokenRefreshed,
  })  : _config = config,
        _httpClient = httpClient;

  final AppConfig _config;
  final http.Client _httpClient;
  final TokenStorage? tokenStorage;
  final VoidCallback? onUnauthorized;
  final VoidCallback? onTokenRefreshed;

  Future<bool>? _refreshFuture;

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

  Future<Object?> putJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    String? bearerToken,
    String fallbackMessage = '요청 처리에 실패했습니다.',
  }) {
    return _requestJson(
      method: 'PUT',
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

  Future<Object?> deleteJson(
    String path, {
    Map<String, String>? headers,
    String? bearerToken,
    String fallbackMessage = '요청 처리에 실패했습니다.',
  }) {
    return _requestJson(
      method: 'DELETE',
      path: path,
      headers: headers,
      bearerToken: bearerToken,
      fallbackMessage: fallbackMessage,
    );
  }

  Future<Uint8List> getBytes(
    String path, {
    Map<String, String>? headers,
    String? bearerToken,
    String fallbackMessage = '파일 다운로드에 실패했습니다.',
  }) async {
    Future<http.Response> sendRequest(String? token) async {
      final requestHeaders = <String, String>{
        'Accept': '*/*',
        if (token != null && token.trim().isNotEmpty) ...{
          'Authorization': 'Bearer ${token.trim()}',
          'access-token': token.trim(),
        },
        ...?headers,
      };
      return _httpClient.get(uri(path), headers: requestHeaders);
    }

    var response = await sendRequest(bearerToken);

    if (response.statusCode == 401 && path != '/api/v1/auth/refresh' && tokenStorage != null) {
      final success = await _refreshToken();
      if (success) {
        final newAccessToken = await tokenStorage!.readAccessToken();
        if (newAccessToken != null && newAccessToken.trim().isNotEmpty) {
          response = await sendRequest(newAccessToken);
        }
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _debugLogFailure(
        method: 'GET(Bytes)',
        path: path,
        statusCode: response.statusCode,
        payload: response.body,
      );
      throw ApiException(
        fallbackMessage,
        statusCode: response.statusCode,
      );
    }

    return response.bodyBytes;
  }

  Future<Object?> uploadFile(
    String path, {
    required List<int> fileBytes,
    required String filename,
    required String fieldName,
    Map<String, String>? headers,
    String? bearerToken,
    String fallbackMessage = '파일 업로드에 실패했습니다.',
  }) async {
    final requestUri = uri(path);
    
    Future<http.Response> sendMultipartRequest(String? token) async {
      final request = http.MultipartRequest('POST', requestUri);
      request.headers['Accept'] = 'application/json';
      if (token != null && token.trim().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${token.trim()}';
        request.headers['access-token'] = token.trim();
      }
      if (headers != null) {
        request.headers.addAll(headers);
      }
      
      final mimeType = lookupMimeType(filename);
      MediaType? mediaType;
      if (mimeType != null) {
        final split = mimeType.split('/');
        if (split.length == 2) {
          mediaType = MediaType(split[0], split[1]);
        }
      }

      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
        contentType: mediaType,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await _httpClient.send(request);
      return http.Response.fromStream(streamedResponse);
    }

    var response = await sendMultipartRequest(bearerToken);

    if (response.statusCode == 401 && path != '/api/v1/auth/refresh' && tokenStorage != null) {
      final success = await _refreshToken();
      if (success) {
        final newAccessToken = await tokenStorage!.readAccessToken();
        if (newAccessToken != null && newAccessToken.trim().isNotEmpty) {
          response = await sendMultipartRequest(newAccessToken);
        }
      }
    }

    final payload = _decodeJson(response.body, fallbackMessage);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _debugLogFailure(
        method: 'POST(Multipart)',
        path: path,
        statusCode: response.statusCode,
        payload: payload,
      );

      if (response.statusCode == 401) {
        final code = _readString(payload, 'code');
        if (code != 'AUTH.INVALID_PARAMS') {
          onUnauthorized?.call();
        }
      }

      throw ApiException(
        extractEnvelopeMessage(payload, fallbackMessage),
        statusCode: response.statusCode,
        code: _readString(payload, 'code'),
        data: _readData(payload),
      );
    }

    ensureEnvelopeSuccess(payload, fallbackMessage);
    return unwrapEnvelopeData(payload);
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
      if (bearerToken != null && bearerToken.trim().isNotEmpty) ...{
        'Authorization': 'Bearer ${bearerToken.trim()}',
        'access-token': bearerToken.trim(),
      },
      ...?headers,
    };

    final encodedBody = body == null ? null : jsonEncode(body);
    if (kDebugMode) {
      debugPrint('[API_REQUEST][$method $path] body: $encodedBody');
    }
    var response = await _send(
      method: method,
      uri: uri(path),
      headers: requestHeaders,
      body: encodedBody,
    );

    if (response.statusCode == 401 && path != '/api/v1/auth/refresh' && tokenStorage != null) {
      final success = await _refreshToken();
      if (success) {
        final newAccessToken = await tokenStorage!.readAccessToken();
        if (newAccessToken != null && newAccessToken.trim().isNotEmpty) {
          requestHeaders['Authorization'] = 'Bearer ${newAccessToken.trim()}';
          requestHeaders['access-token'] = newAccessToken.trim();
          response = await _send(
            method: method,
            uri: uri(path),
            headers: requestHeaders,
            body: encodedBody,
          );
        }
      }
    }

    final payload = _decodeJson(response.body, fallbackMessage);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _debugLogFailure(
        method: method,
        path: path,
        statusCode: response.statusCode,
        payload: payload,
      );

      if (response.statusCode == 401) {
        final code = _readString(payload, 'code');
        if (code != 'AUTH.INVALID_PARAMS') {
          onUnauthorized?.call();
        }
      }

      throw ApiException(
        extractEnvelopeMessage(payload, fallbackMessage),
        statusCode: response.statusCode,
        code: _readString(payload, 'code'),
        data: _readData(payload),
      );
    }

    ensureEnvelopeSuccess(payload, fallbackMessage);
    return unwrapEnvelopeData(payload);
  }

  Future<bool> _refreshToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _doRefreshToken();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefreshToken() async {
    if (tokenStorage == null) return false;
    final rToken = await tokenStorage!.readRefreshToken();
    if (rToken == null || rToken.trim().isEmpty) return false;

    try {
      final refreshResponse = await _send(
        method: 'POST',
        uri: uri('/api/v1/auth/refresh'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refreshToken': rToken.trim()}),
      );

      if (refreshResponse.statusCode == 201 || refreshResponse.statusCode == 200) {
        final payload = _decodeJson(refreshResponse.body, 'Refresh Failed');
        final data = payload is Map && payload.containsKey('data') ? payload['data'] : payload;

        if (data is Map) {
          final newAccess = data['accessToken'] as String?;
          final newRefresh = data['refreshToken'] as String?;

          if (newAccess != null && newAccess.trim().isNotEmpty) {
            await tokenStorage!.saveAccessToken(newAccess);
            if (newRefresh != null && newRefresh.trim().isNotEmpty) {
              await tokenStorage!.saveRefreshToken(newRefresh);
            }
            onTokenRefreshed?.call();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiClient] Token refresh error: $e');
      }
      return false;
    }
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
      case 'PUT':
        return _httpClient.put(uri, headers: headers, body: body);
      case 'PATCH':
        return _httpClient.patch(uri, headers: headers, body: body);
      case 'DELETE':
        return _httpClient.delete(uri, headers: headers);
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

  void _debugLogFailure({
    required String method,
    required String path,
    required int statusCode,
    required Object? payload,
  }) {
    if (!kDebugMode) {
      return;
    }

    final code = _readString(payload, 'code') ?? '-';
    final message = extractEnvelopeMessage(payload, '응답 메시지 없음');
    final data = _readData(payload);
    final dataText = data == null ? '-' : jsonEncode(data);
    debugPrint(
      '[api][$method $path] 실패 status=$statusCode code=$code '
      'message=$message data=$dataText',
    );
  }

  String? _readString(Object? payload, String key) {
    if (payload is! Map) {
      return null;
    }

    final value = payload[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  Object? _readData(Object? payload) {
    if (payload is! Map || !payload.containsKey('data')) {
      return null;
    }

    return payload['data'];
  }
}

final unauthorizedHandlerProvider = Provider<VoidCallback?>((ref) => null);

final tokenRefreshedHandlerProvider = Provider<VoidCallback?>((ref) => null);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    httpClient: ref.watch(httpClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: ref.watch(unauthorizedHandlerProvider),
    onTokenRefreshed: ref.watch(tokenRefreshedHandlerProvider),
  );
});
