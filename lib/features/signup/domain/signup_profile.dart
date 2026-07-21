import '../../../core/utils/json_reader.dart';
import '../../auth/domain/social_login_result.dart';
import '../../auth/domain/social_provider.dart';

class SignupProfileDraft {
  const SignupProfileDraft({
    this.name = '',
    this.provider,
    this.providerLabel = '',
    this.phone = '',
    this.zipCode = '',
    this.address1 = '',
    this.address2 = '',
    this.birthDate = '',
  });

  factory SignupProfileDraft.fromSocialLogin(SocialLoginResult result) {
    return SignupProfileDraft(
      name: result.profile.name,
      provider: result.profile.provider,
      providerLabel: result.profile.providerLabel,
      phone: result.profile.phone,
    );
  }

  final String name;
  final SocialProvider? provider;
  final String providerLabel;
  final String phone;
  final String zipCode;
  final String address1;
  final String address2;
  final String birthDate;

  SignupProfileDraft copyWith({
    String? name,
    SocialProvider? provider,
    String? providerLabel,
    String? phone,
    String? zipCode,
    String? address1,
    String? address2,
    String? birthDate,
  }) {
    return SignupProfileDraft(
      name: name ?? this.name,
      provider: provider ?? this.provider,
      providerLabel: providerLabel ?? this.providerLabel,
      phone: phone ?? this.phone,
      zipCode: zipCode ?? this.zipCode,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}

class SignupProfileInit {
  const SignupProfileInit({this.name, this.phoneNumber, this.provider});

  factory SignupProfileInit.fromJson(Object? payload) {
    final data = payload is Map ? payload : const <String, Object?>{};

    return SignupProfileInit(
      name: _readString(data, 'name'),
      phoneNumber:
          _readString(data, 'phoneNumber') ?? _readString(data, 'phone'),
      provider: SocialProvider.fromKey(_readString(data, 'provider') ?? ''),
    );
  }

  final String? name;
  final String? phoneNumber;
  final SocialProvider? provider;

  SignupProfileDraft mergeInto(SignupProfileDraft profile) {
    final providerLabel = provider?.label;

    return profile.copyWith(
      name: name?.trim().isNotEmpty == true ? name!.trim() : profile.name,
      phone: phoneNumber?.trim().isNotEmpty == true
          ? phoneNumber!.trim()
          : profile.phone,
      provider: provider ?? profile.provider,
      providerLabel: providerLabel ?? profile.providerLabel,
    );
  }

  static String? _readString(Map<dynamic, dynamic> data, String key) =>
      JsonReader.stringFrom(data, [key]);
}
