# web3.0_petnurim_app

펫누림 플러터앱

## 개발 방향

- 일반 앱 화면은 Flutter로 구현합니다.
- Daum/Kakao 주소검색, 웹 전용 본인인증처럼 웹 사용이 불가피한 흐름만 WebView로 분리합니다.
- 네이티브 SDK 연동, 보안 토큰 저장, 딥링크 처리는 Flutter/native 영역에서 담당합니다.

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
- **메인 커스텀 헤더 (MainHeader)**: 피그마 원본 SVG(로고, 알림 종, 프로필) 연동 및 아이콘 사이즈 제약 최적화, 마이페이지 및 알림 센터 라우팅 연결
- **고객센터 (CustomerCenterScreen)**: 아코디언 확장형 공지사항 목록 및 자주 묻는 질문/1:1문의 탭바 기반 화면 연동. 특히 **1:1 문의**는 피그마 Node 644:10773 ("1:1문의_목록")에 기반하여 답변준비/답변완료 배지 구분, Cursor 기반 무한 스크롤 페이지네이션 연동 완료.
- **1:1 문의 등록 및 첨부파일 연동 (QnaCreateScreen)**:
  - 문의 유형 선택, 제목 및 내용 입력을 통한 문의글 등록 완료.
  - **사진 첨부**: 카메라 촬영 및 앨범 이미지 선택(`image_picker`)을 통한 실제 이미지 파일 업로드 연동. 확장자 기반 MIME 타입 감지 로직 적용(`mime`, `http_parser` 활용).
  - **파일 첨부**: 로컬 디바이스 파일 선택(`file_picker` 8.x)을 통한 일반 파일(최대 30MB) 업로드 및 연동 완료.
  - **인증 예외 방어**: 짧은 글자 수 등 백엔드 유효성 검사 실패(`AUTH.INVALID_PARAMS`) 시 401 상태 코드가 수신되어도 로그아웃 및 로그인 화면으로 튕기지 않도록 `ApiClient` 예외 필터링 추가.
  - **유효성 검증 강화**: 프론트엔드단에서 제목 최소 2자, 내용 최소 5자 이상일 경우에만 제출할 수 있도록 검증 강화.
- **알림 센터 (NotificationScreen)**: 공통 알림 카드 위젯(`NurimTextCard`)을 활용한 Short/Truncated/Expanded 상태 지원 및 모두읽음 처리 기능 탑재

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
    notification/       알림 센터 화면
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
/my/customer-center 고객센터
/notification-center 알림 센터
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
  --dart-define=KAKAO_NATIVE_APP_KEY=930bf238e56cb22cf6484fa8af790a5a \
  --dart-define=NAVER_CLIENT_ID=rOPP7lBMsxvpvDDFcrwF \
  --dart-define=NAVER_CLIENT_SECRET=Jdxpqldi9t \
  --dart-define=NAVER_CLIENT_NAME=DKDOCTOR
```

## 현재 검증 상태

- **정적 분석 및 테스트**: `flutter analyze` 및 `flutter test` 전체 테스트 시나리오 통과 완료
- **동작 검증 범위**:
  - 소셜 로그인 연동(Kakao/Naver) 및 신규 가입 흐름 진입 검증
  - 회원가입 1~3단계(약관 동의 -> 본인인증 -> 주소검색 WebView/생년월일 입력 프로필 저장) 검증 완료
  - 회원 정보 조회(`MyInfoScreen`), 날짜 휠 피커(한국어 대응), 로그아웃 및 회원탈퇴(WithdrawScreen) 실서버 통신 및 토큰 제거 전체 라이프사이클 동작 검증 완료
  - 고객센터(`CustomerCenterScreen`) 공지사항 아코디언 목록 및 1:1 문의 목록 API(Cursor Pagination) 연동 검증 완료
  - 1:1 문의 등록(`QnaCreateScreen`) 첨부파일 실물(사진/파일) 업로드 연동 및 유효성 검증 예외 방어 기능 검증 완료
  - 알림 센터(`NotificationScreen`) 및 공통 카드 위젯(`NurimTextCard`)의 피그마 스펙(종 색상, 모두읽음 헤더 액션 등) 동기화 및 동적 접기/펼치기 반응형 검증 완료
- **플랫폼 빌드**: Android 실단말 디버그 실행(`SM G991N`) 및 iOS 빌드 확인 (`flutter build ios --no-codesign`) 완료


