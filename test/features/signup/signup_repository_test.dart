import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:new_petnurim_app/core/api/api_client.dart';
import 'package:new_petnurim_app/core/config/app_config.dart';
import 'package:new_petnurim_app/core/storage/token_storage.dart';
import 'package:new_petnurim_app/features/signup/data/signup_repository.dart';
import 'package:new_petnurim_app/features/signup/domain/signup_profile.dart';
import 'package:new_petnurim_app/features/signup/domain/signup_terms.dart';

void main() {
  test('활성 약관 목록을 카테고리 그룹 응답에서 정렬해 반환한다', () async {
    final repository = BackendSignupRepository(
      apiClient: ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://api.petnurim.test/api/v1/terms?categories=SIGNUP%2CSECURITY',
          );

          return http.Response(
            jsonEncode({
              'code': 'COMMON.SUCCESS',
              'data': {
                'SECURITY': [
                  {
                    'termsId': 'security-1',
                    'termsNm': 'Privacy',
                    'termsCategory': 'SECURITY',
                    'requiredType': 'REQUIRED',
                    'sortNo': 2,
                  },
                ],
                'SIGNUP': [
                  {
                    'termsId': 'signup-1',
                    'termsNm': 'Service',
                    'termsCategory': 'SIGNUP',
                    'requiredType': 'REQUIRED',
                    'sortNo': 1,
                  },
                ],
              },
            }),
            200,
          );
        }),
      ),
      tokenStorage: InMemoryTokenStorage(),
    );

    final terms = await repository.fetchActiveTerms(
      categories: const [TermsCategory.signup, TermsCategory.security],
    );

    expect(terms.map((term) => term.termsId), ['signup-1', 'security-1']);
    expect(terms.first.isRequired, isTrue);
  });

  test('약관 동의 저장은 signup token과 동의 목록을 전송한다', () async {
    final repository = BackendSignupRepository(
      apiClient: ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer signup-token');
          expect(jsonDecode(request.body), {
            'terms': [
              {'termsId': 'terms-1', 'agreed': true},
            ],
          });

          return http.Response(jsonEncode({'code': 'COMMON.SUCCESS'}), 200);
        }),
      ),
      tokenStorage: InMemoryTokenStorage(),
    );

    await repository.submitTerms(
      signupToken: 'signup-token',
      agreements: const [TermAgreement(termsId: 'terms-1', agreed: true)],
    );
  });

  test('회원정보 저장은 생년월일을 API 형식으로 전송한다', () async {
    final repository = BackendSignupRepository(
      apiClient: ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
        httpClient: MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(request.headers['Authorization'], 'Bearer signup-token');
          expect(jsonDecode(request.body), {
            'zipCode': '12345',
            'address1': 'Seoul Gangnam',
            'address2': '101호',
            'birthDate': '20020202',
          });

          return http.Response(jsonEncode({'code': 'COMMON.SUCCESS'}), 200);
        }),
      ),
      tokenStorage: InMemoryTokenStorage(),
    );

    await repository.submitProfile(
      signupToken: 'signup-token',
      profile: const SignupProfileDraft(
        zipCode: '12345',
        address1: 'Seoul Gangnam',
        address2: '101호',
        birthDate: '2002년 2월 2일',
      ),
    );
  });

  test('가입 완료는 access token을 저장한다', () async {
    final tokenStorage = InMemoryTokenStorage();
    final repository = BackendSignupRepository(
      apiClient: ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer signup-token');

          return http.Response(
            jsonEncode({
              'code': 'COMMON.SUCCESS',
              'data': {'accessToken': 'access-token'},
            }),
            200,
          );
        }),
      ),
      tokenStorage: tokenStorage,
    );

    final result = await repository.completeSignup(signupToken: 'signup-token');

    expect(result.accessToken, 'access-token');
    expect(await tokenStorage.readAccessToken(), 'access-token');
  });
}
