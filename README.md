# new_petnurim_app

펫누림 앱을 Flutter 중심으로 새로 구현하는 저장소입니다.

이 저장소는 기존 `dkdrsmlee-dev/nurimAppDemo`의 Flutter WebView 셸 +
React UI 구조를 대체합니다. 기존 데모는 동작 기준과 API 흐름을 확인하는
참고 자료로만 사용하고, 새 앱의 주요 화면은 Flutter 위젯으로 구현합니다.

## 개발 방향

- 일반 앱 화면은 Flutter로 구현합니다.
- Daum/Kakao 주소검색, 웹 전용 본인인증처럼 웹 사용이 불가피한 흐름만 WebView로 분리합니다.
- 네이티브 SDK 연동, 보안 토큰 저장, 딥링크 처리는 Flutter/native 영역에서 담당합니다.
- 기존 React에 있던 API 호출과 회원가입 흐름은 Dart 서비스로 옮깁니다.

## 현재 적용된 기본 구성

- 라우팅: `go_router`
- 상태관리/의존성 주입: `flutter_riverpod`
- Kakao 로그인: `kakao_flutter_sdk`
- Naver 로그인: Android/iOS 네이티브 채널 + Naver SDK
- API 통신: `http` 기반 공통 클라이언트와 `COMMON.SUCCESS` envelope 처리
- 보안 저장소: `flutter_secure_storage`
- 앱 진입점: `ProviderScope` + `PetnurimApp`
- 기본 화면 흐름: 스플래시, 온보딩, 인증 시작, 회원가입 단계, 홈 탭, 주소검색 WebView 후보
- 회원가입 흐름: 약관 조회/저장, 휴대폰 인증 처리, 초기 프로필 조회, 회원정보 저장, 가입 완료 API 연결
- 로그인 후 홈 구조: 홈, 진료, 반려동물, 마이 하단 내비게이션과 토큰 삭제 로그아웃

## 초기 구조

```txt
lib/
  app/                 앱 셸, 라우팅, 최상위 조립
  core/
    api/               API 클라이언트와 응답 envelope 처리
    config/            실행 환경 설정
    storage/           토큰과 로컬 상태 저장
  features/
    splash/
    onboarding/
    auth/
    signup/             약관, 본인인증, 프로필, 가입 완료
    home/
    webview/           꼭 필요한 WebView 흐름
  native/              Kakao, Naver, PASS, 플랫폼 브리지
```

## 현재 라우트

```txt
/                 스플래시
/onboarding       온보딩
/auth/start       로그인 시작
/signup/terms     약관 동의
/signup/verify    본인인증
/signup/profile   회원정보 입력
/signup/complete  가입 완료
/home             홈
/webview/address  주소검색 WebView 후보
```

## 실행

```bash
flutter pub get
flutter run
```

로컬 백엔드나 소셜 로그인 앱 키가 바뀌면 실행 시 `--dart-define`으로 주입합니다.

```bash
flutter run \
  --dart-define=NURIM_API_BASE_URL=http://192.168.0.147:4011 \
  --dart-define=KAKAO_NATIVE_APP_KEY=카카오_네이티브_앱키 \
  --dart-define=NAVER_CLIENT_ID=네이버_클라이언트_ID \
  --dart-define=NAVER_CLIENT_SECRET=네이버_클라이언트_SECRET \
  --dart-define=NAVER_CLIENT_NAME=네이버_앱_이름
```

## 현재 검증 상태

- `flutter analyze`
- `flutter test`
- Android 실단말 디버그 실행: `SM G991N`
- Android 실단말 소셜 로그인: Kakao/Naver 성공 확인
- iOS 빌드 확인: `flutter build ios --no-codesign`

## 참고 소스

- 기존 데모 저장소: https://github.com/dkdrsmlee-dev/nurimAppDemo.git
- 새 저장소 원격: https://github.com/dkdrsmlee-dev/new_petnurim_app.git
