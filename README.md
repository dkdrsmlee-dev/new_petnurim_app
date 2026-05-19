# new_petnurim_app

Flutter-first Pet Nurim mobile app.

This repository replaces the previous hybrid demo approach in
`dkdrsmlee-dev/nurimAppDemo`. The old demo is used as a behavioral reference,
but this app should be built primarily with Flutter widgets.

## Direction

- Build normal app screens in Flutter.
- Keep WebView only for flows that are practically web-bound, such as Daum/Kakao address search or a web-only verification provider flow.
- Keep native SDK integrations, secure token storage, and deep link handling on the Flutter/native side.
- Port React-side API and signup flow logic into Dart services.

## Initial Structure

```txt
lib/
  app/                 App shell, routing, and top-level composition
  core/
    api/               API client and response envelope handling
    config/            Runtime configuration
    storage/           Token and local state persistence
  features/
    splash/
    onboarding/
    auth/
    signup/
    home/
    webview/           Narrow WebView flows only
  native/              Kakao, Naver, PASS, and platform bridges
```

## Run

```bash
flutter pub get
flutter run
```

## Source Reference

- Previous demo repository: https://github.com/dkdrsmlee-dev/nurimAppDemo.git
- New repository remote: https://github.com/dkdrsmlee-dev/new_petnurim_app.git
