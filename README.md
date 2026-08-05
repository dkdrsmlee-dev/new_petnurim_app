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
- **API 통신**: `http` 기반 공통 클라이언트와 `COMMON.SUCCESS` envelope 처리 (API 요청 로깅 탑재). 401 수신 시 refresh 토큰으로 액세스 토큰 자동 갱신 후 재시도하며, 갱신 성공 시 `onTokenRefreshed` 콜백으로 `appBootstrapStateProvider`를 invalidate하여 `accessTokenProvider`를 최신 토큰으로 동기화.
- **인증 파일 이미지 로딩 (AuthedFileImage)**: 프로필 이미지 등 인증 토큰이 필요한 `/api/v1/files/{id}/download` 리소스를 `ApiClient.getBytes`(401 → 토큰 자동 refresh → 재시도) 기반 커스텀 `ImageProvider`로 로딩. 유휴로 액세스 토큰이 만료돼도 이미지가 자가 복구되며, Flutter ImageCache에 `fileId` 기준으로 편입되어 리빌드 시 재다운로드를 방지. 마이펫 상세/리스트/마이페이지/수정/등록완료 화면에 공통 적용.
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
- **마이 펫 촬영 및 촬영 내역 (Camera & Shooting History)**:
  - **카메라 미션 가이드 화면 (`CameraMissionGuideScreen`)**: 미션 안내 및 펫 보유 현황별 동적 촬영 프로세스 분기 처리 (0마리: 등록 화면 / 1마리: 바로 촬영 / 2마리 이상: 펫 선택).
  - **펫 선택 화면 (`PetSelectScreen`)**: 마이펫 촬영 미션 참여 시 등록된 반려동물이 2마리 이상일 때 특정 반려동물을 선택하는 화면(Figma USR-EVT-018) 연동.
  - **촬영 내역 화면 (`ShootingHistoryScreen`)**: 반려동물별 이번 달 촬영 참여 횟수, 누적 리워드 조회 및 내역이 없는 빈 화면(Empty State) 레이아웃(Figma USR-EVT-019) 구현.
  - **공통 반려동물 요약 카드 (`CameraHistoryCard`)**: 펫의 대표 즐겨찾기 상태, 기본 정보(이름, 품종, 나이, 성별) 및 획득 리워드를 깔끔하게 표현하는 카드 위젯.
  - **디자인 디테일 / 커스텀 SVG 아이콘**: 피그마 원본 벡터에 최적화된 굴뚝 모양의 홈 버튼(`_homeIconSvg`), 긴 화살표 모양의 뒤로가기 버튼(`_backIconSvg`), 즐겨찾기 별 배지, 출석/기록 달력 체크, 3D 누적 리워드 코인 아이콘 등을 커스텀 SVG로 정밀 적용.

## 코드 구조 개선 (리팩토링)

동작 변화 없이(시각/기능 동일) 중복을 제거하고 단일 출처로 통합하는 리팩토링을 진행했습니다. 각 항목은 정적 분석·단위 테스트·Android 실단말(`SM G991N`) 3중 검증을 거쳤습니다.

- **색상 디자인 토큰 (`AppColors`)**: 앱 전역에 하드코딩돼 있던 `Color(0xFF..)` 리터럴과 화면별 로컬 색상 상수를 `lib/core/theme/app_colors.dart`의 의미 기반 토큰(`primary`/`textStrong`/`border`/`bgGray` 등)으로 일원화. `core/widgets` 및 feature 화면 60여 개 파일에 적용(값 hex 1:1 유지 → 시각 변화 없음)하여 색상 변경 시 토큰 파일 한 곳만 수정하면 전역 반영. 카카오/네이버 등 브랜드색·1회성 색은 리터럴로 유지.
- **JSON 파싱 유틸 (`JsonReader`)**: 여러 도메인 모델과 `ApiClient`에 중복 구현돼 있던 문자열/정수/불리언 파싱 규칙을 `lib/core/utils/json_reader.dart`로 통합(`coerceString`/`stringFrom`/`plainString`/`asInt`/`coerceBool` 등). 각 모델은 고유 기본값(''/fallback 등)만 남긴 얇은 래퍼로 위임하여 동작을 100% 보존했고, 직접 검증하는 단위 테스트(`test/core/utils/json_reader_test.dart`)를 추가.
- **공통 폼 위젯 (`form_fields`)**: 마이펫 폼 화면들에 반복되던 필드 라벨(라벨+빨강 필수 dot), pill 형태 선택 버튼, 입력 데코레이션을 `lib/core/widgets/form_fields.dart`(`NurimFieldLabel`/`NurimSelectableTab`/`nurimInputDecoration`)로 추출하여 `MyPetEdit`/`MyPetDetailForm`/`MyPetStoryForm`/`MyPetHealthForm`에 적용.
- **미구현 메뉴 안내**: 마이페이지의 목적지 없는 메뉴(결제 수단 변경/설정)의 빈 핸들러를 `ToastUtil`로 "준비 중인 기능입니다." 토스트를 노출하도록 정리하여 먹통 탭을 제거. (서비스 약관은 이후 실제 화면으로 구현 — 아래 검증 상태 참고)
- **펫 공통코드 매핑 중앙화 (`pet_codes.dart`)**: 성별(`MALE`/`FEMALE`↔남아/여아)·펫종류(`DOG`/`CAT`)·`Y`/`N` 매핑을 마이펫 화면 8곳에 흩어져 있던 하드코딩·매직스트링에서 `lib/features/member/domain/pet_codes.dart`(`PetGender`/`PetType`/`YesNo`)로 통합. 표시는 서버 코드명(`~CodeNm`) 우선 + fallback 구조를 유지하여 동작 보존.
- **공통코드 조회 (`common_code_repository`)**: 회원 탈퇴 사유를 하드코딩에서 백엔드 공통코드(`GET /common-codes/{groupKey}`, `WITHDRAW_REASON_TYPE`)로 전환. 응답 필드가 `code`/`name`으로 내려와 여러 키를 방어적으로 파싱하고, 조회 실패/로딩 시 fallback 목록을 사용해 화면이 항상 동작하도록 함.
- **약관 상세 화면 공용화 (`TermsDetailScreen`)**: 회원가입 약관 동의(기존 바텀시트+평문)와 마이페이지 서비스 약관에서 각기 다르게 보여주던 약관 본문을, `lib/features/signup/terms_detail_screen.dart`의 공용 전체화면(HtmlWidget 렌더 + 확인 버튼)으로 통합. 가입 약관의 raw HTML 노출 버그도 해결.

## 초기 구조

```txt
lib/
  app/                 앱 셸, 라우팅, 최상위 조립
  core/
    api/               API 클라이언트와 응답 envelope 처리
    config/            실행 환경 설정
    storage/           토큰과 로컬 상태 저장
    theme/             색상 디자인 토큰(AppColors)
    utils/             JSON 파싱(JsonReader), 토스트 등 공통 유틸
    widgets/           공통 위젯(라벨/탭/버튼/카드/폼 필드 등)
  features/
    splash/
    auth/
    signup/             약관, 본인인증, 프로필, 가입 완료
    member/             나의 정보, 회원탈퇴 화면 및 회원 도메인
    home/
    notification/       알림 센터 화면
    webview/           Daum 우편번호 검색 WebView 화면
    camera/            마이 펫 촬영, 펫 선택, 촬영 내역 화면
  native/              Kakao, Naver, PASS, 플랫폼 브리지
```

## 현재 라우트

```txt
/                 스플래시
/auth/start       로그인 시작
/signup/terms     약관 동의
/signup/verify    본인인증
/signup/profile   회원정보 입력
/signup/complete  가입 완료
/home             홈 (메인 탭)
/my/info          나의 정보 (마이페이지 상세)
/my/withdraw      회원탈퇴
/my/customer-center 고객센터
/my/service-terms 서비스 약관 (목록/상세)
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
  --dart-define=NURIM_API_BASE_URL=http://api-dev.petnurim.kr \
  --dart-define=KAKAO_NATIVE_APP_KEY=34beb18e7458f8a9c0df634000099456 \
  --dart-define=NAVER_CLIENT_ID=ls2RTw_ovGeS7ZB1Zs3F \
  --dart-define=NAVER_CLIENT_SECRET=tNMaYJSMRd \
  --dart-define=NAVER_CLIENT_NAME=펫누림
```

### 카카오 로그인 설정 가이드

카카오 개발자 콘솔(Kakao Developers)의 앱 키가 변경되거나 신규 앱 생성 시 아래의 설정 사항들을 디벨로퍼스 웹 콘솔에 맞춰 반드시 등록해 주어야 정상 연동됩니다:

1. **플랫폼 설정 (내 애플리케이션 > 플랫폼)**:
   - **iOS 플랫폼**:
     - 번들 ID: `com.dkdr.newpetnurim`
   - **Android 플랫폼**:
     - 패키지명: `com.dkdr.newpetnurim`
     - 키 해시(Key Hash): 개발/릴리즈용 PC 고유의 키 해시 값 등록 필수 (예: 로컬 디버그용 `JAEFipIm+HpUFyARLT6L92ewpS8=`)

2. **카카오 로그인 기능 활성화**:
   - `제품 설정 > 카카오 로그인` 메뉴에서 **간편로그인 활성화 상태를 "ON"**으로 켭니다.

3. **동의 항목 설정**:
   - `카카오 로그인 > 동의 항목` 메뉴에서 백엔드 가입 연동 목적에 부합하는 개인정보(예: **프로필 정보 - 닉네임/프로필 사진** 등) 권한을 활성화합니다.

## 현재 검증 상태

- **정적 분석 및 테스트**: `flutter analyze` 및 `flutter test` 전체 테스트 시나리오 통과 완료
- **동작 검증 범위**:
  - 소셜 로그인 연동(Kakao/Naver) 및 신규 가입 흐름 진입 검증
  - 회원가입 1~3단계(약관 동의 -> 본인인증 -> 주소검색 WebView/생년월일 입력 프로필 저장) 검증 완료
  - **회원 정보 입력 화면 (`ProfileScreen`)**: 피그마 시안(`USR-AUT-090-회원정보 입력(SNS)`) 스펙에 맞추어 연결계정(provider 표기)·생년월일(읽기 전용) 필드, 주소 검색/상세 입력 필드 및 다음 버튼 개편 완료. **생년월일은 백엔드 `profile-init` 응답의 본인인증 값(`birthDate`, ISO)을 자동 채움(읽기전용)** — 기존 하드코딩 기본값(`2004-01-01`) 자동 대입 방식을 대체하여 실제 생년월일이 제출되도록 조치. 연결계정도 가짜 이메일 조합 대신 provider(`카카오 계정` 등)로 정직하게 표기
  - **회원가입 완료 화면 리뉴얼 (`CompleteScreen`)**: 피그마 시안(`USR-AUT-094-회원가입 완료`)에 부합하는 일러스트 및 하단 듀얼 버튼("마이펫 등록" 및 "홈으로") 개편 완료. 마이펫 등록 선택 시 앱 전역 로그인 세션 상태를 안전하게 갱신(invalidate)한 뒤 마이펫 추가 화면(`MyPetAddScreen`)으로 부드럽고 정밀하게 라우팅되도록 연동 완료
  - **마이펫 프로필 이미지 다운로드 인증 헤더 오류 조치 (`MyPage`, `MyPetList`, `MyPetDetail`, `MyPetEdit`, `MyPetAddComplete`)**: 백엔드의 파일 다운로드 API가 `access-token` 헤더를 필수로 인가 검증함에 따라, 이미지 뷰어들의 `NetworkImage` / `Image.network` 구성 요소에서 `Authorization` 헤더와 함께 `access-token` 헤더를 공동 전송하도록 전면 개편하여 사진 등록 및 변경 시 즉각 반영되도록 조치 완료
  - 회원 정보 조회(`MyInfoScreen`), 날짜 휠 피커(한국어 대응), 로그아웃 및 회원탈퇴(WithdrawScreen) 실서버 통신 및 토큰 제거 전체 라이프사이클 동작 검증 완료
  - 고객센터(`CustomerCenterScreen`) 공지사항 아코디언 목록 및 1:1 문의 목록 API(Cursor Pagination) 연동 검증 완료
  - 1:1 문의 등록(`QnaCreateScreen`) 첨부파일 실물(사진/파일) 업로드 연동 및 유효성 검증 예외 방어 기능 검증 완료
  - 알림 센터(`NotificationScreen`) 및 공통 카드 위젯(`NurimTextCard`)의 피그마 스펙(종 색상, 모두읽음 헤더 액션 등) 동기화 및 동적 접기/펼치기 반응형 검증 완료
  - **고객센터 FAQ 탭 (`CustomerCenterScreen`)**: 자주 묻는 질문 탭을 백엔드 FAQ(`GET /board/faqs`, 커서 페이징) 아코디언으로 구현(공지사항 패턴 재사용, HTML 답변 렌더). 실단말 검증 완료
  - **서비스 약관 (`ServiceTermsScreen`/`TermsDetailScreen`)**: 마이페이지 서비스 약관을 활성 약관 목록 + 상세(HtmlWidget) 화면으로 구현하고 가입 약관 상세와 공용화. 실단말 검증 완료
  - **확인 다이얼로그 정비**: 촬영 미션 중단·회원가입 중단(약관/인증)·펫 0마리 안내("아이 등록이 필요해요")·로그아웃 확인 팝업을 피그마 문구/구성에 맞춰 추가·정비. 실단말 검증 완료
  - **회원 탈퇴 사유 공통코드화 (`WithdrawScreen`)**: 하드코딩 사유를 백엔드 공통코드(`WITHDRAW_REASON_TYPE`) 조회로 전환. 실단말에서 조회·렌더·직접입력·글자수 카운터 검증 완료
  - **이미지 로딩 UX/성능 개선 (홈·출석·촬영·마이펫)**: 첫 진입 시 이미지가 늦게 뜨는 체감을 개선. (1) **프리워밍** — 홈 이미지(캐러셀 배너·리워드 썸네일·출석/촬영 상세)를 스플래시·홈 양쪽에서 백그라운드로 미리 받아(`lib/features/home/home_image_preloader.dart`) 진입 시 캐시 히트로 즉시 표시(신규 로그인/토큰복원 경로 모두 커버). (2) **셔머 스켈레톤** — 로딩 구간에 국내 표준형 셔머(`lib/core/widgets/shimmer_box.dart`, 대각선 `topLeft→centerRight`·중립 회색 `#E0E0E0/#F5F5F5`·1500ms)를 공용 `frameBuilder`로 적용해 빈 화면→팝인 대신 자연스러운 전환. (3) **에셋 플래시 제거** — 촬영예시(`CameraMissionGuideScreen`)에서 상세 로딩 중 폴백 에셋이 잠깐 노출되던 것을 셔머로 대체. (4) **다운로드 크기 축소** — 캐러셀 배너·마이펫 프로필 이미지를 원본→`medium` variant로 전환(실측 배너 3.2MB→815KB, `downloadFallback: true`로 medium 부재 시 원본 폴백). 실단말(`R3CR209JAWX`) 캐시 계측·렌더 검증 완료
  - **휴대폰 번호 변경 본인인증 연동 (`MyInfoScreen`)**: 목업을 실제 흐름으로 교체 — 안내 바텀시트 → KCP 본인인증(`POST /identity-verification/request`, purposeCode=CHANGE_PHONE, access token) → 완료 시 `PATCH /member/phone`(requestToken) → `memberInfoProvider` 재조회로 새 번호 자동 반영 → 성공 다이얼로그. 가입용 `KcpCertWebViewScreen` 재사용(신규 화면 없음). 실단말(`R3CR209JAWX`)에서 실제 KCP 인증 완료 → 번호 갱신까지 실연동 검증 완료(백엔드 500 `UK_USER_CONTACT_PRIMARY` 수정 후). 참고: `CHANGE_PHONE`은 번호만 변경(이름 등은 미변경).
  - **마이펫 리워드 요약 API 연동 (마이펫 상세·마이페이지·마이펫 리스트)**: 하드코딩(`28,000P` 등)을 실데이터로 교체 — `GET /api/v1/users/my-pets/{myPetId}/reward`(`PetRewardSummary`: currentReward/totalEarnReward/currentMonthEarnReward/currentMonthUseReward). 상세의 총 리워드·이번 달 적립·사용 + 펫 카드(마이페이지/리스트)의 리워드를 `petRewardSummaryProvider`(펫별) + 공용 `formatThousands`(`core/utils/number_format.dart`)로 표시(로딩/실패 시 `-`). 실단말 검증 완료(실제 리워드 0인 펫은 0P로 정상 표시).
  - **마이펫 리워드 내역 화면 (`PetRewardHistoryScreen`, USR-RWD-011)**: 피그마대로 구현 — 이용내역(`historyType=ALL`)/소멸내역(`EXPIRE`) 탭 + 리스트 헤더(전체 N·최신순) + 커서 무한스크롤(`GET /api/v1/users/my-pets/{myPetId}/reward/history`) + 빈/에러 상태. 항목: 제목·날짜·구분(적립/사용/소멸/복구)·증감(±PR, 적립·복구=보라 +, 사용·소멸=검정 −). 마이펫 상세 "리워드 내역 >" 버튼에서 진입. 실단말에서 화면·탭 전환·API 호출(ALL/EXPIRE) + **실데이터 항목 렌더 검증 완료**(출석 체크로 적립된 "출석 기본 리워드" 항목이 제목·날짜(2026.08.04)·구분(적립)·금액(+100PR)까지 정확히 표시됨 → 방어적 파서의 후보 키가 백엔드 item 필드와 일치 확인). ※ 응답 item이 스웨거엔 무타입(object)이라 `PetRewardHistoryItem`은 관리자 ledger 필드 기준 **방어적 파싱**(여러 후보 키)으로 구현. "전체 N"은 커서 특성상 로드된 개수 기준.
  - **출석 이벤트 펫별 진행 (`AttendancePetSelectScreen` + `AttendanceScreen`)**: 백엔드가 출석에 `myPetId`를 **필수**로 추가함에 따라 펫별 출석으로 전환 — 홈 출석 카드 탭 시 등록 펫 수로 분기(0마리 등록 안내 / 1마리 바로 출석 / 2마리+ 펫 선택), 선택한 펫으로 `GET /attendance/{eventMasterId}?myPetId=`·`POST .../check {myPetId}` 호출. 신규 펫 선택 화면(헤더 "마이 펫 출석", 안내 "출석 체크할\n아이를 선택해 주세요.", `/users/my-pets` 재사용, `PetSelectCard.showHistory=false`로 내역 버튼 숨김). `attendanceProvider` 키를 `(eventMasterId, myPetId)` 레코드로 변경. 프리워밍은 출석 상세가 펫별이라 제외(진입 시 셔머 로드). 실단말 검증: 펫 선택→`?myPetId=` 성공(기존 `400 PET.MY_PET_NOT_FOUND` 해소).
- **플랫폼 빌드/배포**: Android 실단말 디버그 실행(`SM G991N`, `R3CR209JAWX`) 및 iOS 빌드 확인(`flutter build ios --no-codesign`) 완료. Firebase App Distribution(`web3-petnurim`) 테스트 빌드 배포. 배포 절차·초기 세팅(macOS 처음 시작 기준)은 [`docs/firebase-app-distribution.md`](docs/firebase-app-distribution.md) 참고.


