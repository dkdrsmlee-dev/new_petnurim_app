enum SocialProvider {
  kakao,
  naver;

  String get backendValue => name.toUpperCase();

  String get label {
    switch (this) {
      case SocialProvider.kakao:
        return '카카오';
      case SocialProvider.naver:
        return '네이버';
    }
  }

  static SocialProvider? fromKey(String value) {
    final normalized = value.trim().toLowerCase();
    for (final provider in SocialProvider.values) {
      if (provider.name == normalized) {
        return provider;
      }
    }

    return null;
  }
}
