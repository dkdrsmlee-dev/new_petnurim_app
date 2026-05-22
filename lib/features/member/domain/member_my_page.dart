class MemberMyPage {
  const MemberMyPage({
    required this.userId,
    required this.name,
    required this.email,
    required this.joinDt,
    this.outDt,
    this.sleeperDt,
  });

  factory MemberMyPage.fromJson(Object? json) {
    if (json is! Map) {
      return const MemberMyPage(userId: '', name: '', email: '', joinDt: '');
    }

    return MemberMyPage(
      userId: _readString(json['userId']),
      name: _readString(json['name']),
      email: _readString(json['email']),
      joinDt: _readString(json['joinDt']),
      outDt: _readNullableString(json['outDt']),
      sleeperDt: _readNullableString(json['sleeperDt']),
    );
  }

  final String userId;
  final String name;
  final String email;
  final String joinDt;
  final String? outDt;
  final String? sleeperDt;

  static String _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return '';
  }

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}
