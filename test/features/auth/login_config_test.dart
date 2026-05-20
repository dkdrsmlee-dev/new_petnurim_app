import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/features/auth/domain/login_config.dart';
import 'package:new_petnurim_app/features/auth/domain/social_provider.dart';

void main() {
  test('로그인 설정 응답을 소셜 로그인 활성 상태로 변환한다', () {
    final config = LoginConfig.fromJson({
      'idLogin': 'false',
      'snsLogin': 'true',
      'providers': {'kakao': 1, 'NAVER': true},
    });

    expect(config.idLogin, isFalse);
    expect(config.snsLogin, isTrue);
    expect(config.isProviderEnabled(SocialProvider.kakao), isTrue);
    expect(config.isProviderEnabled(SocialProvider.naver), isTrue);
  });

  test('SNS 로그인이 꺼져 있으면 provider 값이 있어도 비활성으로 본다', () {
    final config = LoginConfig.fromJson({
      'snsLogin': false,
      'providers': {'kakao': true, 'naver': true},
    });

    expect(config.isProviderEnabled(SocialProvider.kakao), isFalse);
    expect(config.isProviderEnabled(SocialProvider.naver), isFalse);
  });
}
