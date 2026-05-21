class MemberInfo {
  const MemberInfo({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.birthDate,
  });

  factory MemberInfo.fromJson(Object? json) {
    if (json is! Map) {
      return const MemberInfo(
        name: '',
        email: '',
        phoneNumber: '',
        address: '',
        birthDate: '',
      );
    }

    return MemberInfo(
      name: _readString(json['name'], ''),
      email: _readString(json['email'], ''),
      phoneNumber: _readString(json['phoneNumber'], ''),
      address: _readString(json['address'], ''),
      birthDate: _readString(json['birthDate'], ''),
    );
  }

  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final String birthDate;

  static String _readString(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }
}
