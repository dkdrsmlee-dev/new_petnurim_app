import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:new_petnurim_app/core/api/api_client.dart';
import 'package:new_petnurim_app/core/config/app_config.dart';
import 'package:new_petnurim_app/core/storage/token_storage.dart';
import 'package:new_petnurim_app/features/member/data/member_repository.dart';

void main() {
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
