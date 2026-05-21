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

- **라우팅**: `go_router`
- **상태관리/의존성 주입**: `flutter_riverpod`
- **Kakao 로그인**: `kakao_flutter_sdk`
- **Naver 로그인**: Android/iOS 네이티브 채널 + Naver SDK
- **API 통신**: `http` 기반 공통 클라이언트와 `COMMON.SUCCESS` envelope 처리 (API 요청 로깅 탑재)
- **보안 저장소**: `flutter_secure_storage`
- **다국어/로컬라이제이션**: `flutter_localizations` 설정을 추가하여 날짜 휠 피커 등 네이티브 위젯 한글화 대응
- **앱 진입점**: `ProviderScope` + `PetnurimApp`
- **회원가입 흐름**: 약관 조회/저장, PASS 스타일 본인인증 처리, 초기 프로필 조회, 우편번호 주소검색 웹뷰, 회원정보 저장 및 가입 완료 API 연동
- **나의 정보 및 회원탈퇴**: 나의 정보 화면에서의 생년월일(CupertinoDatePicker)/주소 변경, 로그아웃 확인 및 회원탈퇴(WithdrawScreen) 사유 선택/동의/서버 연동 플로우 완료
- **로그인 후 홈 구조**: 홈, 진료, 반려동물, 마이 하단 내비게이션

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
    member/             나의 정보, 회원탈퇴 화면 및 회원 도메인
    home/
    webview/           Daum 우편번호 검색 WebView 화면
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
/home             홈 (메인 탭)
/my/info          나의 정보 (마이페이지 상세)
/my/withdraw      회원탈퇴
/webview/address  주소검색 WebView
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

- **정적 분석 및 테스트**: `flutter analyze` 및 `flutter test` 전체 테스트 시나리오 통과 완료
- **동작 검증 범위**:
  - 소셜 로그인 연동(Kakao/Naver) 및 신규 가입 흐름 진입 검증
  - 회원가입 1~3단계(약관 동의 -> 본인인증 -> 주소검색 WebView/생년월일 입력 프로필 저장) 검증 완료
  - 회원 정보 조회(`MyInfoScreen`), 날짜 휠 피커(한국어 대응), 로그아웃 및 회원탈퇴(WithdrawScreen) 실서버 통신 및 토큰 제거 전체 라이프사이클 동작 검증 완료
- **플랫폼 빌드**: Android 실단말 디버그 실행(`SM G991N`) 및 iOS 빌드 확인 (`flutter build ios --no-codesign`) 완료

## 참고 소스

- 기존 데모 저장소: https://github.com/dkdrsmlee-dev/nurimAppDemo.git
- 새 저장소 원격: https://github.com/dkdrsmlee-dev/new_petnurim_app.git
