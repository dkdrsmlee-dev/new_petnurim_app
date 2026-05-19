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
    signup/
    home/
    webview/           꼭 필요한 WebView 흐름
  native/              Kakao, Naver, PASS, 플랫폼 브리지
```

## 실행

```bash
flutter pub get
flutter run
```

## 참고 소스

- 기존 데모 저장소: https://github.com/dkdrsmlee-dev/nurimAppDemo.git
- 새 저장소 원격: https://github.com/dkdrsmlee-dev/new_petnurim_app.git
