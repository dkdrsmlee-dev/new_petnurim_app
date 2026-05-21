import 'dart:async';
import 'dart:io';

import '../../../core/api/api_exception.dart';
import 'auth_exception.dart';

String readAuthErrorMessage(Object error, String fallbackMessage) {
  if (error is AuthException) {
    return error.message;
  }

  if (error is ApiException) {
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
