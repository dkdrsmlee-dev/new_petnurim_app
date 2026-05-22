import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:new_petnurim_app/core/api/api_client.dart';
import 'package:new_petnurim_app/core/api/api_exception.dart';
import 'package:new_petnurim_app/core/config/app_config.dart';

void main() {
  test('GET JSON 요청은 성공 envelope의 data를 반환한다', () async {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.petnurim.test/api/v1/auth/config',
        );

        return http.Response(
          jsonEncode({
            'code': 'COMMON.SUCCESS',
            'data': {'snsLogin': true},
          }),
          200,
        );
      }),
    );

    final data = await client.getJson('/api/v1/auth/config');

    expect(data, {'snsLogin': true});
  });

  test('POST JSON 요청은 Authorization 헤더와 body를 보낸다', () async {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer signup-token');
        expect(jsonDecode(request.body), {'terms': []});

        return http.Response(jsonEncode({'code': 'COMMON.SUCCESS'}), 200);
      }),
    );

    final data = await client.postJson(
      '/api/v1/auth/signup/terms',
      bearerToken: ' signup-token ',
      body: {'terms': []},
    );

    expect(data, <String, Object?>{});
  });

  test('HTTP 실패 응답은 envelope 메시지를 담은 ApiException을 던진다', () async {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
      httpClient: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode({'message': '권한이 없습니다.'})),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    expect(
      () => client.getJson('/api/v1/me', fallbackMessage: '회원 조회 실패'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.message, 'message', '권한이 없습니다.')
            .having((error) => error.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('HTTP 401 응답은 onUnauthorized 콜백을 호출한다', () async {
    var called = false;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
      httpClient: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode({'message': '권한이 없습니다.'})),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      onUnauthorized: () {
        called = true;
      },
    );

    try {
      await client.getJson('/api/v1/me');
    } catch (_) {}

    expect(called, isTrue);
  });
}
