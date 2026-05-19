# 프로젝트 컨텍스트

## 참고 프로젝트

`nurimAppDemo`는 이전 하이브리드 데모입니다.

- 저장소: https://github.com/dkdrsmlee-dev/nurimAppDemo.git
- 구조: Flutter WebView 셸 + React UI
- Flutter 역할: WebView 호스팅, JWT 저장 브리지, Kakao SDK, Naver 네이티브 채널, 딥링크
- React 역할: 스플래시, 온보딩, 소셜 로그인 시작, 약관, 본인인증 목업, 회원정보 입력, 가입 완료, 홈, 앱 상태, API 호출

## 새 구현 방향

`new_petnurim_app`는 Flutter 중심 앱으로 구현합니다.

- 앱이 직접 소유하는 화면은 Flutter 위젯으로 다시 만듭니다.
- `nurimAppDemo`는 전체 코드를 끼워 넣는 대상이 아니라, 동작과 API 기준을 확인하는 참고 자료로 씁니다.
- 외부 웹 흐름이 필요한 경우에만 WebView를 유지합니다.
- `bootstrap`, `saveToken`, `clearToken` 같은 브리지 개념은 Flutter 서비스로 흡수합니다.

## 2단계 앱 골격

- `lib/main.dart`: `ProviderScope`로 앱을 시작합니다.
- `lib/app/petnurim_app.dart`: `MaterialApp.router` 기반 앱 셸입니다.
- `lib/app/app_router.dart`: `go_router` 라우팅 정의입니다.
- `lib/app/app_theme.dart`: 앱 공통 Material 테마입니다.
- `lib/core`: API, 설정, 토큰 저장소의 초기 인터페이스 위치입니다.
- `lib/features`: 화면 흐름별 최소 Flutter 화면입니다.

## WebView 후보 영역

- Daum/Kakao 주소검색
- 제공사가 웹 흐름을 요구하는 PASS 또는 본인인증
- Flutter 텍스트 렌더링으로 부족한 복잡한 HTML 약관 본문

## 초기에 옮길 API

- `GET /api/v1/auth/config`
- `POST /api/v1/auth/social/{provider}`
- `GET /api/v1/terms`
- `POST /api/v1/auth/signup/terms`
- `POST /api/v1/auth/signup/verify-phone`
- `GET /api/v1/auth/signup/profile-init`
- `PATCH /api/v1/auth/signup/profile`
- `POST /api/v1/auth/signup/complete`

## 권장 구현 순서

1. 앱 셸, 라우팅, 상태, 토큰 저장
2. API 클라이언트와 응답 envelope 처리
3. Kakao/Naver 로그인과 백엔드 소셜 로그인
4. 회원가입 흐름 화면과 서비스
5. 주소검색 또는 본인인증용 최소 WebView 흐름
6. 홈, 하단 내비게이션, 로그아웃, 프로필 진입점
