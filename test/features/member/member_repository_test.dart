import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:new_petnurim_app/core/api/api_client.dart';
import 'package:new_petnurim_app/core/config/app_config.dart';
import 'package:new_petnurim_app/core/storage/token_storage.dart';
import 'package:new_petnurim_app/features/member/data/member_repository.dart';

void main() {
  test('마이페이지 조회 API는 access token으로 사용자 요약 정보를 조회한다', () async {
    final repository = BackendMemberRepository(
      tokenStorage: InMemoryTokenStorage(initialAccessToken: 'member-token'),
      apiClient: ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://api.petnurim.test/api/v1/member/mypage',
          );
          expect(request.headers['Authorization'], 'Bearer member-token');

          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'code': 'COMMON.SUCCESS',
                'data': {
                  'userId': 'hong01',
                  'name': '홍길동',
                  'email': 'hong@example.com',
                  'joinDt': '2026-02-27T00:00:00.000Z',
                  'outDt': null,
                  'sleeperDt': null,
                },
              }),
            ),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );

    final result = await repository.getMyPage();

    expect(result.userId, 'hong01');
    expect(result.name, '홍길동');
    expect(result.email, 'hong@example.com');
    expect(result.joinDt, '2026-02-27T00:00:00.000Z');
  });

  test('내정보 조회 API는 access token으로 상세 회원 정보를 조회한다', () async {
    final repository = BackendMemberRepository(
      tokenStorage: InMemoryTokenStorage(initialAccessToken: 'member-token'),
      apiClient: ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://api.petnurim.test/api/v1/member/me',
          );
          expect(request.headers['Authorization'], 'Bearer member-token');

          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'code': 'COMMON.SUCCESS',
                'data': {
                  'name': '홍길동',
                  'email': 'email@email.co.kr',
                  'phoneNumber': '010-1234-1234',
                  'address': '서울시 강남구 역삼동 123-45 12층 오크빌 1204호',
                  'birthDate': '20100307',
                },
              }),
            ),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );

    final result = await repository.getMemberInfo();

    expect(result.name, '홍길동');
    expect(result.email, 'email@email.co.kr');
    expect(result.phoneNumber, '010-1234-1234');
    expect(result.birthDate, '20100307');
  });

  test('회원탈퇴 API는 access token과 탈퇴 동의 값을 전송한다', () async {
    final repository = BackendMemberRepository(
      tokenStorage: InMemoryTokenStorage(initialAccessToken: 'member-token'),
      apiClient: ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'https://api.petnurim.test/api/v1/member/withdraw',
          );
          expect(request.headers['Authorization'], 'Bearer member-token');
          expect(jsonDecode(request.body), {
            'reasonCode': 'ETC',
            'withdrawalAgreeYn': 'Y',
            'reasonText': '앱에서 회원탈퇴 요청',
          });

          return http.Response(
            jsonEncode({
              'code': 'COMMON.SUCCESS',
              'data': {
                'withdrawalStatus': 'PENDING',
                'effectiveDt': '2026-05-30 23:59:59',
              },
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.withdraw(
      reasonCode: 'ETC',
      reasonText: '앱에서 회원탈퇴 요청',
    );

    expect(result.withdrawalStatus, 'PENDING');
    expect(result.effectiveDt, '2026-05-30 23:59:59');
  });
}
