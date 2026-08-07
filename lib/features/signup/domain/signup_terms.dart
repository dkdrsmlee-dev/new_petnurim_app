import '../../../core/utils/json_reader.dart';
import '../../auth/domain/auth_exception.dart';

enum TermsCategory {
  signup('SIGNUP'),
  security('SECURITY'),
  marketing('MARKETING'),
  etc('ETC');

  const TermsCategory(this.apiValue);

  final String apiValue;

  static TermsCategory fromValue(String value) {
    final normalized = value.trim().toUpperCase();
    for (final category in TermsCategory.values) {
      if (category.apiValue == normalized) {
        return category;
      }
    }

    return TermsCategory.etc;
  }
}

class ActiveTerm {
  const ActiveTerm({
    required this.termsId,
    required this.termsHistoryId,
    required this.termsKey,
    required this.termsName,
    required this.content,
    required this.termsCategory,
    required this.requiredType,
    required this.sortNo,
    required this.status,
  });

  factory ActiveTerm.fromJson(Object? payload) {
    if (payload is! Map) {
      throw const AuthException('약관 항목 응답 형식이 올바르지 않습니다.');
    }

    return ActiveTerm(
      // 백엔드 약관 API 개편(target 기준 조회) 대응: 신규 키 우선, 구 키 fallback
      termsId: _readString(payload, 'termsMasterId', fallbackKey: 'termsId'),
      // 현재 버전 이력 PK(멤버십 가입 검증/동의 저장에 사용).
      termsHistoryId: _readString(payload, 'termsHistoryId'),
      termsKey: _readString(payload, 'termsKey'),
      termsName: _readString(payload, 'termsName', fallbackKey: 'termsNm'),
      content: _readString(payload, 'content'),
      termsCategory: TermsCategory.fromValue(
        _readString(payload, 'termsCategoryCode', fallbackKey: 'termsCategory'),
      ),
      requiredType: _readString(
        payload,
        'requiredTypeCode',
        fallbackKey: 'requiredType',
      ),
      sortNo: _readInt(payload, 'sortNo'),
      status: _readString(payload, 'status'),
    );
  }

  final String termsId;

  /// 현재 버전 이력 PK(TERMS_HISTORY_ID). 멤버십 가입 검증/동의 저장에 사용.
  final String termsHistoryId;
  final String termsKey;
  final String termsName;
  final String content;
  final TermsCategory termsCategory;
  final String requiredType;
  final int sortNo;
  final String status;

  bool get isRequired => requiredType.trim().toUpperCase() == 'REQUIRED';

  /// termsHistoryId 정수 변환(파싱 실패 시 null).
  int? get termsHistoryIdInt => int.tryParse(termsHistoryId.trim());

  String get requiredLabel => isRequired ? '필수' : '선택';

  String get contentSummary {
    final normalized = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '약관 상세 내용을 확인해 주세요.';
    }
    return normalized.length > 72
        ? '${normalized.substring(0, 72)}...'
        : normalized;
  }

  static String _readString(
    Map<dynamic, dynamic> data,
    String key, {
    String? fallbackKey,
  }) {
    var value = data[key];
    if (value == null && fallbackKey != null) {
      value = data[fallbackKey];
    }
    return JsonReader.coerceString(value) ?? '';
  }

  static int _readInt(Map<dynamic, dynamic> data, String key) =>
      JsonReader.asInt(data[key]);
}

class TermAgreement {
  const TermAgreement({required this.termsId, required this.agreed});

  final String termsId;
  final bool agreed;

  Map<String, Object?> toJson() {
    final parsedInt = int.tryParse(termsId);
    return {
      'termsId': parsedInt ?? termsId,
      'agreed': agreed,
    };
  }
}
