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
      termsId: _readString(payload, 'termsId'),
      termsKey: _readString(payload, 'termsKey'),
      termsName: _readString(payload, 'termsNm'),
      content: _readString(payload, 'content'),
      termsCategory: TermsCategory.fromValue(
        _readString(payload, 'termsCategory'),
      ),
      requiredType: _readString(payload, 'requiredType'),
      sortNo: _readInt(payload, 'sortNo'),
      status: _readString(payload, 'status'),
    );
  }

  final String termsId;
  final String termsKey;
  final String termsName;
  final String content;
  final TermsCategory termsCategory;
  final String requiredType;
  final int sortNo;
  final String status;

  bool get isRequired => requiredType.trim().toUpperCase() == 'REQUIRED';

  String get requiredLabel => isRequired ? '필수' : '선택';

  static String _readString(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is String) {
      return value.trim();
    }
    if (value is num || value is bool) {
      return '$value';
    }

    return '';
  }

  static int _readInt(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }

    return 0;
  }
}

class TermAgreement {
  const TermAgreement({required this.termsId, required this.agreed});

  final String termsId;
  final bool agreed;

  Map<String, Object?> toJson() {
    return {'termsId': termsId, 'agreed': agreed};
  }
}
