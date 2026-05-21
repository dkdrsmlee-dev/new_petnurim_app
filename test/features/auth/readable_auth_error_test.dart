import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/api/api_exception.dart';
import 'package:new_petnurim_app/features/auth/domain/auth_exception.dart';
import 'package:new_petnurim_app/features/auth/domain/readable_auth_error.dart';

void main() {
  test('AuthException 메시지를 사용자 메시지로 사용한다', () {
    expect(
      readAuthErrorMessage(const AuthException('인증 오류'), '기본 오류'),
      '인증 오류',
    );
  });

  test('ApiException 메시지와 HTTP 상태를 사용자 메시지로 사용한다', () {
    expect(
      readAuthErrorMessage(
        const ApiException('소셜 로그인 처리에 실패했습니다.', statusCode: 500),
        '기본 오류',
      ),
      '소셜 로그인 처리에 실패했습니다. (HTTP 500)',
    );
  });

  test('알 수 없는 오류는 기본 메시지를 사용한다', () {
    expect(readAuthErrorMessage(Exception('숨김'), '기본 오류'), '기본 오류');
  });
}
