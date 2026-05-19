import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/api/api_envelope.dart';
import 'package:new_petnurim_app/core/api/api_exception.dart';

void main() {
  test('data가 있는 envelope는 data를 반환한다', () {
    final payload = {
      'code': 'COMMON.SUCCESS',
      'data': {'name': '누림'},
    };

    expect(unwrapEnvelopeData(payload), {'name': '누림'});
  });

  test('실패 code가 있으면 ApiException을 던진다', () {
    final payload = {'code': 'AUTH.FAIL', 'msg': '로그인이 필요합니다.'};

    expect(
      () => ensureEnvelopeSuccess(payload, '요청 실패'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '로그인이 필요합니다.',
        ),
      ),
    );
  });

  test('중첩된 data.message를 fallback보다 우선한다', () {
    final payload = {
      'data': {'message': '상세 오류입니다.'},
    };

    expect(extractEnvelopeMessage(payload, '기본 오류'), '상세 오류입니다.');
  });
}
