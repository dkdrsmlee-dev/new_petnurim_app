import 'dart:async';
import 'dart:io';

import '../../../core/api/api_exception.dart';
import 'auth_exception.dart';

String readAuthErrorMessage(Object error, String fallbackMessage) {
  if (error is AuthException) {
    return error.message;
  }

  if (error is ApiException) {
    final friendly = _friendlyMessageForCode(error.code);
    if (friendly != null) {
      return friendly;
    }
    return error.toString();
  }

  if (error is SocketException) {
    return '서버에 연결하지 못했습니다. 네트워크 상태와 API 서버 주소를 확인해 주세요.';
  }

  if (error is TimeoutException) {
    return '요청 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.';
  }

  return fallbackMessage;
}

/// 백엔드 에러 코드를 사용자 친화적 한글 메시지로 매핑한다(없으면 null).
String? _friendlyMessageForCode(String? code) {
  switch (code) {
    case 'AUTH.IDENTITY_NOT_VERIFIED':
      return '본인인증이 완료되지 않았어요. 다시 시도해 주세요.';
  }
  return null;
}
