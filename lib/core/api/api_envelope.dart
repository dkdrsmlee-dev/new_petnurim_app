import 'api_exception.dart';

const defaultSuccessCode = 'COMMON.SUCCESS';

typedef JsonMap = Map<String, Object?>;

String extractEnvelopeMessage(Object? payload, String fallback) {
  if (payload is! JsonMap) {
    return fallback;
  }

  final message = payload['msg'] ?? payload['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }

  final data = payload['data'];
  if (data is JsonMap) {
    final nestedMessage = data['msg'] ?? data['message'];
    if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
      return nestedMessage.trim();
    }
  }

  return fallback;
}

void ensureEnvelopeSuccess(
  Object? payload,
  String fallback, {
  String successCode = defaultSuccessCode,
}) {
  if (payload is! JsonMap) {
    return;
  }

  final code = payload['code'];
  if (code is String && code.isNotEmpty && code != successCode) {
    throw ApiException(extractEnvelopeMessage(payload, fallback));
  }
}

Object? unwrapEnvelopeData(Object? payload) {
  if (payload is! JsonMap) {
    return payload;
  }

  if (payload.containsKey('data')) {
    return payload['data'];
  }

  const envelopeKeys = {'code', 'msg', 'message', 'data'};
  final hasOnlyEnvelopeKeys = payload.keys.every(envelopeKeys.contains);
  if (!hasOnlyEnvelopeKeys && payload.isNotEmpty) {
    return payload;
  }

  return <String, Object?>{};
}
