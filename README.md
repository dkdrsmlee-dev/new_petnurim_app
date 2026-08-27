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
- **나의 정보 및 회원탈퇴**: 나의 정보 화면에서의 생년월일(CupertinoDatePicker)/주소 변경, 로그아웃 확인 및 회원탈퇴(WithdrawScreen) 사유 선택/동의/서버 연동 플로우 완료. 탈퇴 응답의 **`withdrawalStatus`로 분기** — `COMPLETED`면 토큰 정리·로그아웃, **`PENDING`(구독 기간 남음)이면 로그아웃하지 않고 안내 팝업**(USR-MIF-025, Figma 201:5927): "{`effectiveDt`를 yyyy년 M월 dd일}까지 구독 중인 서비스가 있어요. / 남은 구독 기간이 종료된 후 다시 탈퇴를 신청해 주세요."(`EdgeButtonDialog` 단일 확인). ※ 탈퇴 종료일은 `effectiveDt`(탈퇴 효력일시)이며 `benefitEndDate`(cancel API 전용)가 아니다. 탈퇴 화면 상단엔 **활성 구독 안내 박스**(USR-MIF-024 "구독 서비스 있음", Figma 196:7510)를 표시 — 회원 단위 구독 조회 API가 없어 **펫별 API를 집계**(`withdrawActiveSubscriptionsProvider`: 펫 목록 → 각 펫 멤버십 → 가입 펫만 `GET /memberships/{id}`로 `periodEndDt` 조회)해 구독 중인 펫을 **모두** "구독 멤버십 · {상품명} ({periodEndDt}까지)"(빨강)로 나열하고, 구독이 없으면 박스를 숨긴다.
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
- **멤버십 혜택 화면 (`MembershipBenefitsScreen`, USR-MBS-010)**: 마이펫 상세에서 멤버십 미이용 펫의 "멤버십 혜택 보기"로 진입하는 정적 안내 화면(Figma 239:26098 / 263:9035). 퍼플 그라데이션 히어로에 피그마 원본 데코를 정밀 반영 — 코인 4개(옆면 코인 42.89°·가격카드 좌하단에 겹치는 코인 28.83° 회전), 별 3개(SVG `fill`을 명시 흰색으로 교정·`colorFilter` 강제), 배경 글로우 원 2개(Flutter 블러). 프레임 절대좌표는 유동 레이아웃과 어긋나므로 카드에 겹치는 코인4·별9는 가격카드 위젯에 직접 앵커링, 배경 글로우는 콘텐츠 뒤/코인·별은 콘텐츠 앞 2층 분리. 왕관은 피그마 크라운 벡터 SVG(`crown.svg`, `#F8B600`) 사용. "멤버십 즉시 구독하기"는 멤버십 구독 약관 동의 화면으로 이동.
- **멤버십 구독 약관 동의 화면 (`MembershipTermsAgreementScreen`, USR-PAY-012)**: 멤버십 혜택 "멤버십 즉시 구독하기"에서 진입하는 구독 약관 동의 단계(Figma 277:14344 미동의 / 523:16973 전체동의). **회원가입 약관 동의(`TermsScreen`, target=SIGNUP)와는 별개** — 로그인 사용자가 `GET /api/v1/terms?target=SUBSCRIPTION`(인증 불필요)에서 약관을 **동적으로 받아** 렌더(별도 `subscriptionTermsProvider`, 약관 조회 메서드·`ActiveTerm` 모델·`TermsDetailScreen`은 공용 재사용). 상태 전환을 디자인대로 반영 — 체크박스는 채운 원+흰 체크(미동의 `#E8EBF1`↔동의 `#7F4FFF`), 라벨 굵기/색(Medium `#87909E`↔SemiBold `#30343C`), "다음" 버튼 활성/비활성(`#7F4FFF`↔`#E8EBF1`). 전체 동의↔개별 동기화, 모든 필수 체크 시 "다음" 활성. "다음"에서 동의 약관의 `termsHistoryId`를 수집해 **`POST /memberships/validate`**(가입 사전 검증) 통과 후 **결제수단 유무로 분기**한다 — 등록 카드가 있으면 "본인 명의 카드 선택" 바텀시트로 결제할 카드를 고른 뒤 "구독하기" 확인 화면에서 "결제하기"로 구독, 없으면 (디자인에 없는 중간 화면 없이) 토스 카드 등록창을 띄워 지갑 등록 후 그 카드로 구독한다(아래 구독 결제 흐름 참고). 멤버십은 펫별이라 `myPetId`·`membershipMasterId`를 관통한다.
- **멤버십 구독 결제 흐름 (`MembershipTermsAgreementScreen` 내 분기 + `TossBillingTestWebViewScreen`, USR-PAY-011)**: 약관 "다음" 이후 결제수단 유무로 분기한다(별도 카드 등록 화면 없음). **등록 카드가 있으면** "본인 명의 카드 선택" 바텀시트(`PaymentMethodSelectSheet`, Figma 277:14037, USR-PAY-011)로 결제할 카드를 고른다 — scrim 60% 딤 + 상단 라운드16 시트에 제목("본인 명의 카드 선택")·X 닫기, 활성 카드 리스트(결제수단 관리 화면과 동일한 `CardIssuerIcon`+`cardLabel` 재사용, 기본 카드에 보라 체크✓), 카드 탭=선택+진행(X·바깥 탭=취소로 약관에 잔류). 카드 추가 항목은 없음(마이페이지에서 선등록). **단, 활성 카드가 1개뿐이면 선택지가 없으므로 이 시트를 생략하고 그 카드로 바로 진행**하며, 이 경우 확인 화면의 "결제 수단 >" 변경 화살표·탭도 숨긴다(변경 대상 없음). 카드를 고르면 **"구독하기" 확인 화면**(`SubscribeConfirmScreen`, Figma 547:13693, USR-MBS-014)으로 이동해 구독 정보·결제 정보(월 이용료·부가세·결제 방식·다음 결제일·총 결제 금액)·결제 수단(탭 시 카드 선택 시트 재오픈으로 변경)·유의사항을 확인하고, 하단 **"N원 결제하기"**를 눌러야 선택 카드(`userPaymentMethodId`)로 Billing Auth 없이 **`POST /api/v1/memberships`** 구독이 생성된다. 이 화면은 흰 섹션 + 회색 구분 배경(`AppColors.sectionGap`)으로 디자인의 섹션 분리감을 반영하고, "멤버십 이용약관에 동의 >"는 약관 목록 바텀시트(구독 이용약관/개인정보 처리방침 — 약관 동의 화면과 **동일한** `subscriptionTermsProvider` 2건, 각 항목 상세 HTML)로 열람시킨다(기획서·디자인 미정 인터랙션 → 협의로 결정). 백엔드가 부가세/공급가 breakdown·결제 전 다음 결제일을 주지 않으므로 부가세=`monthlyFee×10/110`, 다음 결제일=오늘+1개월으로 표기(디자인 목업 숫자는 플레이스홀더). **미등록이면** (디자인에 없는 중간 화면을 거치지 않고) 곧바로 **토스 자동결제(빌링) WebView**를 띄운다 — 국내 표준상 카드번호/CVC/비밀번호를 앱이 직접 받지 않고 PG(토스페이먼츠) 결제창에서 입력받으므로 Figma 커스텀 카드 폼은 쓰지 않는다. 등록을 마치면 토스가 successUrl 로 리다이렉트하고 WebView 가 그 URL 에서 **`authKey`를 추출**한다(`webview_flutter`, success/fail URL 감지 — 휴대폰 변경 `KcpCertWebViewScreen`과 동일 패턴). 이 `authKey`·`customerKey`를 먼저 **`POST /api/v1/payment-methods`** 로 결제수단 지갑에 등록해 **결제수단 목록에도 카드가 남도록** 한 뒤, 재조회한 그 카드의 `userPaymentMethodId`로 `POST /memberships` 구독을 생성한다(토스 카드를 구독에만 쓰고 지갑에 안 남기는 문제 방지). 토스 clientKey 는 **`GET /api/v1/payments/config`**(백엔드 secretKey 와 짝이 되는 상점 clientKey, public)에서 받아 WebView 에 전달한다 — 임의 공개 테스트 키를 쓰면 백엔드가 authKey→billingKey 발급에 실패(`502 PAYMENT.BILLING_ISSUE_FAILED`)하므로 반드시 백엔드와 같은 상점 키여야 한다(현재 백엔드 TEST 환경이라 실제 청구 없음). 구독 성공 시 **① "결제 카드가 정상적으로 등록되었습니다." 다이얼로그**(Figma 748:50978, 공용 `EdgeButtonDialog`, 미등록 분기에서만) → **② 결제 완료 화면**(`MembershipCompleteScreen`, USR-PAY-018/289:9512)을 순차로 띄운다(완료 이동은 `_goComplete`로 공통화). ②는 전달받은 `membershipId`로 **`GET /api/v1/memberships/{id}`**(상세)를 조회해 구독 상품·금액·결제 방식·결제 수단(카드사+마스킹)·구독 시작일(joinDt)·자동 갱신일(nextBillingDt)을 6행 카드로 보여준다. 확인/X 시 구독 플로우를 걷어내고 마이펫 상세로 복귀(`popUntil` + 혜택 화면 `routeName`)하며, 성공 직후 `petMembershipProvider`를 무효화해 상세가 자동으로 "구독중"으로 갱신된다. 등록/구독 실패나 토스창 취소 시엔 토스트로 안내하고 약관 화면에 남는다.
- **멤버십 해지 플로우 (`MembershipBenefitsScreen` 구독중 상태 + `MembershipCancelScreen`/`MembershipCancelCompleteScreen`, Figma 547:12592·547:14070·593:11560·615:10503·1057:32601)**: 구독 펫의 마이펫 상세 "멤버십 혜택 보기" → 혜택 화면이 **구독 여부로 분기**(미가입=데코 히어로+"즉시 구독하기" / 구독중=크라운·구독 정보·혜택·유의사항 접이식·"멤버십 해지하기"). 구독중 상태는 `membershipDetailProvider`(`GET /memberships/{id}`)로 상품·금액·이용 기간·결제 수단·자동결제일을 바인딩한다(해지 신청 상태면 상단 안내가 "해지 신청된 멤버십입니다./종료일까지 혜택을 이용할 수 있어요." 빨강 문구로 분기 — `isCancelScheduled`). "멤버십 해지하기" → 해지 화면(547:14070)은 **`GET /api/v1/memberships/{id}/cancel-info`**로 남은 이용일수(`benefitRemainingDays`)·이용 종료일·**해지 사유 목록(공통코드 `cancelReasons`)**을 받아 렌더(사유 라디오 **단일 선택**·직접입력(ETC)은 **선택 시에만 입력칸 노출**·유의사항 동의). 사유 1개 이상 + 동의 시 "멤버십 해지하기" 활성 → 확인 다이얼로그(593:11560) → **`POST /api/v1/memberships/{id}/cancel`**(body `{cancelReasonCodes, cancelReasonText?(ETC 시), noticeAgreed:true}`) → 해지 신청 완료 화면(615:10503, 응답의 `cancelRequestDate`·`benefitEndDate` 표시) → 마이펫 상세로 복귀하며 `petMembershipProvider` 무효화로 **"해지 신청" 배지**(1057:32601)·"이용 종료일"로 자동 갱신된다. 혜택 리스트는 `guide.benefits`(공용 위젯 `MembershipBenefitList`, 아이콘은 디자인 고정 매핑). **재구독(해지 취소, Phase 3b)**: 해지 신청 상태의 구독중 혜택 화면 버튼은 "해지 취소하기"로 바뀌며 → 재구독 확인 다이얼로그(900:39130, "멤버십 해지를 취소하시겠어요?" 닫기/해지 취소하기) → **`POST /api/v1/memberships`**(최소 payload `{myPetId, membershipMasterId}` — 기존 billingKey 재사용, customerKey/authKey/terms 불필요) → 완료 토스트(900:39304, "멤버십 해지가 취소되었습니다…") + `membershipDetailProvider`·`petMembershipProvider` 무효화로 ACTIVE 자동 갱신(버튼 "멤버십 해지하기"·상세 "현재 이용 중"·"다음 결제일" 복귀).
- **멤버십 결제 내역 화면 (`MembershipPaymentHistoryScreen`, USR-MBS-012, Figma 239:26305)**: 마이펫 상세 구독중 뷰의 "결제 내역 >"에서 진입. **`GET /api/v1/memberships/{id}/payments`**(`membershipPaymentsProvider`)로 결제 이력을 받아 상단 "전체 N · 최신 내역 순" + 각 행(상품명·결제일(`paidDt`)·결제 수단(카드사+마스킹 "현대카드 (48\*\*)")·금액)을 리스트로 표시한다. 빈 내역은 "결제 내역이 없어요." ※ **gotcha: 이 엔드포인트 `page`는 1-indexed** — `page=0`으로 보내면 `401 AUTH.INVALID_PARAMS`(게다가 ApiClient가 401을 토큰만료로 오인해 재시도 루프) → `page=1`로 조회.

## 코드 구조 개선 (리팩토링)

동작 변화 없이(시각/기능 동일) 중복을 제거하고 단일 출처로 통합하는 리팩토링을 진행했습니다. 각 항목은 정적 분석·단위 테스트·Android 실단말(`SM G991N`) 3중 검증을 거쳤습니다.

- **색상 디자인 토큰 (`AppColors`)**: 앱 전역에 하드코딩돼 있던 `Color(0xFF..)` 리터럴과 화면별 로컬 색상 상수를 `lib/core/theme/app_colors.dart`의 의미 기반 토큰(`primary`/`textStrong`/`border`/`bgGray` 등)으로 일원화. `core/widgets` 및 feature 화면 60여 개 파일에 적용(값 hex 1:1 유지 → 시각 변화 없음)하여 색상 변경 시 토큰 파일 한 곳만 수정하면 전역 반영. 카카오/네이버 등 브랜드색·1회성 색은 리터럴로 유지.
- **JSON 파싱 유틸 (`JsonReader`)**: 여러 도메인 모델과 `ApiClient`에 중복 구현돼 있던 문자열/정수/불리언 파싱 규칙을 `lib/core/utils/json_reader.dart`로 통합(`coerceString`/`stringFrom`/`plainString`/`asInt`/`coerceBool` 등). 각 모델은 고유 기본값(''/fallback 등)만 남긴 얇은 래퍼로 위임하여 동작을 100% 보존했고, 직접 검증하는 단위 테스트(`test/core/utils/json_reader_test.dart`)를 추가.
- **공통 폼 위젯 (`form_fields`)**: 마이펫 폼 화면들에 반복되던 필드 라벨(라벨+빨강 필수 dot), pill 형태 선택 버튼, 입력 데코레이션을 `lib/core/widgets/form_fields.dart`(`NurimFieldLabel`/`NurimSelectableTab`/`nurimInputDecoration`)로 추출하여 `MyPetEdit`/`MyPetDetailForm`/`MyPetStoryForm`/`MyPetHealthForm`에 적용.
- **미구현 메뉴 안내**: 마이페이지의 목적지 없는 메뉴(결제 수단 변경/설정)의 빈 핸들러를 `ToastUtil`로 "준비 중인 기능입니다." 토스트를 노출하도록 정리하여 먹통 탭을 제거. 홈 하단 GNB(`CustomGnb`)도 **홈을 제외한 탭(기프트/문진/경품메타/이벤트)은 "준비 중인 기능입니다." 토스트만 띄우고 화면 전환하지 않도록** 처리(`onTap`에서 `index != 0`이면 토스트 후 return). (서비스 약관은 이후 실제 화면으로 구현 — 아래 검증 상태 참고)
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
  - **휴대폰 번호 변경 본인인증 연동 (`MyInfoScreen`)**: 목업을 실제 흐름으로 교체 — 안내 바텀시트 → KCP 본인인증(`POST /identity-verification/request`, purposeCode=CHANGE_PHONE, access token) → 완료 시 `PATCH /member/phone`(requestToken) → `memberInfoProvider` 재조회로 새 번호 자동 반영 → 성공 다이얼로그. 가입용 `KcpCertWebViewScreen` 재사용(신규 화면 없음). 실단말(`R3CR209JAWX`)에서 실제 KCP 인증 완료 → 번호 갱신까지 실연동 검증 완료(백엔드 500 `UK_USER_CONTACT_PRIMARY` 수정 후). 참고: `CHANGE_PHONE`은 번호만 변경(이름 등은 미변경). **iOS 실단말(iOS 26.5) 검증 중 KCP 콜백 타이밍 레이스 수정(`KcpCertWebViewScreen`)**: 콜백 도달을 `onPageStarted`(콜백 POST 시작 시점)에 감지해 즉시 화면을 닫고 `changePhone`을 호출하던 탓에, iOS에서는 백엔드가 KCP 결과(`POST /identity-verification/kcp/callback`)를 기록하기 **전에** `PATCH /member/phone`이 먼저 도착해 간헐적 `404 IDENTITY_VERIFICATION.NOT_FOUND`가 발생했다(Android는 `onPageStarted`가 늦게 불려 레이스 미발생 → iOS에서만 재현). ① 콜백 종료를 `onPageFinished`(콜백 로드 완료 = 백엔드 기록 완료)로 옮겨 `changePhone`이 **항상** 기록 후 호출되도록 하고, ② iOS(WKWebView)는 POST 네비게이션에서도 `onNavigationRequest`가 호출되므로 콜백 URL을 `prevent`하지 않고 그대로 로드시켜 콜백 POST가 실제 전송되게 조정. iOS/Android 모두 안정 성공(실단말 반복 검증). 같은 화면을 쓰는 회원가입 본인인증도 동일 수혜.
  - **마이펫 리워드 요약 API 연동 (마이펫 상세·마이페이지·마이펫 리스트)**: 하드코딩(`28,000P` 등)을 실데이터로 교체 — `GET /api/v1/users/my-pets/{myPetId}/reward`(`PetRewardSummary`: currentReward/totalEarnReward/currentMonthEarnReward/currentMonthUseReward). 상세의 총 리워드·이번 달 적립·사용 + 펫 카드(마이페이지/리스트)의 리워드를 `petRewardSummaryProvider`(펫별) + 공용 `formatThousands`(`core/utils/number_format.dart`)로 표시(로딩/실패 시 `-`). 실단말 검증 완료(실제 리워드 0인 펫은 0P로 정상 표시).
  - **마이펫 리워드 내역 화면 (`PetRewardHistoryScreen`, USR-RWD-011)**: 피그마대로 구현 — 이용내역(`historyType=ALL`)/소멸내역(`EXPIRE`) 탭 + 리스트 헤더(전체 N·최신순) + 커서 무한스크롤(`GET /api/v1/users/my-pets/{myPetId}/reward/history`) + 빈/에러 상태. 항목: 제목·날짜·구분(적립/사용/소멸/복구)·증감(±PR, 적립·복구=보라 +, 사용·소멸=검정 −). 마이펫 상세 "리워드 내역 >" 버튼에서 진입. 실단말에서 화면·탭 전환·API 호출(ALL/EXPIRE) + **실데이터 항목 렌더 검증 완료**(출석 체크로 적립된 "출석 기본 리워드" 항목이 제목·날짜(2026.08.04)·구분(적립)·금액(+100PR)까지 정확히 표시됨 → 방어적 파서의 후보 키가 백엔드 item 필드와 일치 확인). ※ 응답 item이 스웨거엔 무타입(object)이라 `PetRewardHistoryItem`은 관리자 ledger 필드 기준 **방어적 파싱**(여러 후보 키)으로 구현. "전체 N"은 커서 특성상 로드된 개수 기준.
  - **출석 이벤트 펫별 진행 (`AttendancePetSelectScreen` + `AttendanceScreen`)**: 백엔드가 출석에 `myPetId`를 **필수**로 추가함에 따라 펫별 출석으로 전환 — 홈 출석 카드 탭 시 등록 펫 수로 분기(0마리 등록 안내 / 1마리 바로 출석 / 2마리+ 펫 선택), 선택한 펫으로 `GET /attendance/{eventMasterId}?myPetId=`·`POST .../check {myPetId}` 호출. 신규 펫 선택 화면(헤더 "마이 펫 출석", 안내 "출석 체크할\n아이를 선택해 주세요.", `/users/my-pets` 재사용, `PetSelectCard.showHistory=false`로 내역 버튼 숨김). `attendanceProvider` 키를 `(eventMasterId, myPetId)` 레코드로 변경. 프리워밍은 출석 상세가 펫별이라 제외(진입 시 셔머 로드; 셔머 플레이스홀더는 실제 배너 이미지 비율 `1408×768`=11:6·375폭 기준 ~205px 로 잡아 로드 후 크기 점프 없음 — 레거시 폴백 세로 558 과대예약 수정). 실단말 검증: 펫 선택→`?myPetId=` 성공(기존 `400 PET.MY_PET_NOT_FOUND` 해소).
  - **멤버십 혜택 화면 (`MembershipBenefitsScreen`, USR-MBS-010)**: 마이펫 상세 "멤버십 혜택 보기" → 히어로/가격카드/혜택/안내 정적 화면. 피그마(263:9035) 대비 데코를 정밀 교정 — 코인 4개(옆면 42.89°·카드 좌하단 겹침 28.83°)·별 3개(fill 흰색·카드 겹침 별은 카드 앵커링해 흰색+흰색 소실 해결)·배경 글로우 2개·왕관 SVG(메달 아이콘 오사용 교체)·구독 버튼 화살표 회색(`#6C737F`, `Color/Gray/90`)·하단 안내 내비게이션 바 잘림 및 여백(하단 인셋 반영). 실단말(`R3CR209JAWX`)에서 진입·렌더 및 피그마 대조로 코인 회전·별 표시·크라운·화살표 색·하단 여백을 순차 검증 완료. ※ 실제 구독은 결제(토스 빌링)/백엔드 구독 API 부재로 약관 동의 화면으로 이동.
  - **멤버십 구독 약관 동의 화면 (`MembershipTermsAgreementScreen`, USR-PAY-012)**: 멤버십 혜택 "멤버십 즉시 구독하기" → 구독 약관 동의(Figma 277:14344/523:16973). 회원가입 약관(target=SIGNUP)과 분리된 별도 화면·`subscriptionTermsProvider`(target=SUBSCRIPTION)로 `GET /api/v1/terms`(public) 동적 조회. 실단말(`R3CR209JAWX`)에서 백엔드 약관 2건(멤버십 구독 이용약관/개인정보 처리방침) 렌더, 미동의↔전체동의 상태 전환(체크 색·라벨 굵기·다음 버튼 활성), 개별 토글↔전체동의 동기화, `>` 약관 상세(`TermsDetailScreen` HTML), "다음" → 결제카드 등록 화면 이동까지 검증 완료. ※ 백엔드 구독/카드/빌링 API 및 구독용 동의 저장 엔드포인트 부재로 동의는 클라이언트 게이트.
  - **홈 화면 리디자인 (`HomeScreen`/`HomeEventCarousel`, Figma 116:8397)**: 상단 배너를 디자인 레이아웃으로 전면 교체 — 보라 배경(`#9673ff`) + 3D 친구 일러스트 + 배경 글로우·플랫폼 + 반짝이/별/노란점(Figma 에셋 다운로드) + 하단 그라데이션 + 중앙 흰 텍스트 + dot 페이저, 세로 비율(343:313). 레거시 하드코딩 배너 캐러셀은 제거하고 백엔드 배너 캐러셀(`_ApiBannerCarousel`)은 보존. "매일 받는 리워드 미션" 섹션을 **2열 컴팩트 카드**(기존 `NurimCardBannerSmall` 재사용)로 전환하고 회색(`#F4F6F8`) 배경이 하단까지 채워지도록 배너만 흰색 라운드-바텀 블록으로 감쌈. 미션 카드 아바타는 색 원 안에 **백엔드 이벤트 썸네일**(`thumbnailFileId`, thumb variant·원본 폴백) 표시(없으면 디자인 캐릭터 폴백), 배지 +100P/+20P·연속 출석 N일은 실데이터. 헤더(`MainHeader`)에 **전화/긴급 아이콘**(Figma `Icon/Emergency/24`, 전화 SVG + 빨간 배지·흰 십자)을 벨·프로필 앞에 추가 — 현재는 탭 시 "준비 중" 토스트(고객센터 연결은 보류). 실단말(`R3CR209JAWX`)에서 배너/섹션/카드/백엔드 썸네일 렌더 및 피그마 대조 검증 완료(출석·촬영 카드 탭 동작 유지, 긴급 아이콘 토스트 확인).
  - **홈 미션 카드 주간참여 실데이터 연결 + 완료 후 자동 갱신 (`HomeScreen`, `EventTemplate`)**: 사진 미션 카드의 "주간 참여 N/7일"이 `dayText: '3'` 하드코딩이던 것을, 백엔드가 신설한 **`participationCount`**(templates PHOTO DTO, "이번 주 N회 참여")로 연결 — `EventTemplate`에 `participationCount` 파싱 추가, `home_screen`에서 `photo.participationCount` 표시(출석 카드의 `continuousAttendanceDays`와 동일 패턴). 또한 사진/출석 미션 완료 후 홈 복귀 시 값이 갱신 안 되던(수동 pull-to-refresh 필요) 문제를, 두 미션 카드의 `Navigator.push`를 `await` 후 `eventTemplatesProvider` 무효화로 **자동 갱신** 처리. 실단말(`R3CR209JAWX`) 검증: 원본 응답 대조(participationCount 파싱 일치) + 사진 미션 완료 시 `participate → templates 재조회` 자동 발동·화면 무새로고침 갱신(6/7). 참고: 백엔드가 templates DTO를 `MainAttendanceTemplateDto`(continuousAttendanceDays)/`MainPhotoTemplateDto`(participationCount) 타입별로 분리.
  - **결제카드 등록 흐름 (`MembershipCardRegisterScreen` + `TossBillingTestWebViewScreen`, USR-PAY-011)**: 약관 "다음" → 결제카드 등록. 카드 폼은 만들지 않고 토스 PG WebView로 구성, 흐름(완료/중단 다이얼로그)은 디자인대로. 실단말(`R3CR209JAWX`)에서 약관→카드 등록 이동, "카드 등록창 열기(토스 테스트)"→**실제 토스 카드 등록창(테스트 모드, "실제 결제가 안되는 테스트입니다" 배지) 정상 노출 확인**, 가입 성공 시 **① 카드 등록 완료 다이얼로그 → ② 결제 완료 화면(USR-PAY-018, `MembershipCompleteScreen`)** 순차 노출 후 마이펫 상세 정확 복귀(`popUntil`+`routeName`), 뒤로가기→중단 다이얼로그(나가기→약관 복귀/계속 등록하기)까지 검증 완료. 초기 `test_ck_docs_...`(결제위젯용)는 v1 SDK 빌링에서 "인증되지 않은 키"로 거부, 공개 샘플 키는 백엔드 상점과 달라 billingKey 발급 실패 → 최종적으로 **`GET /api/v1/payments/config`에서 백엔드 상점 clientKey 를 받아 사용**하도록 전환(아래 Phase 1 실연동 참고). **결제 완료 화면(289:9512)**: 실단말에서 실 구독(펫 24·20) 완료 시 상세 조회로 카드사(현대카드 48\*\*)·구독 시작일·자동 갱신일(다음 결제일=한 달 뒤) 정확 렌더 및 Figma 대조 검증, 확인 시 마이펫 상세 "브론즈 현재 이용 중" 자동 갱신 확인. **등록 실패 다이얼로그(USR-PAY-012, 277:14440)**: `POST /memberships` 실패 시 토스트 대신 "등록 실패" + 백엔드 메시지 + `[코드]` 다이얼로그(재시도 가능)로 교체. 현재 전 펫 구독·빌링 정상이라 실패 재현 불가 → 컴파일·analyzer·성공 다이얼로그(748:50978)와 동일 `EdgeButtonDialog` 위젯 검증으로 갈음(실 실패 시 자연 노출).
  - **멤버십 가입 실 API 연동 (Phase 1, `membership_repository`/`membership_models`)**: 백엔드 멤버십 API 신설에 따라 가입 플로우를 실연동 — `GET /memberships/guide`(상품명·월구독료·membershipMasterId 바인딩) → 약관 동의(`termsHistoryId` 수집) → `POST /memberships/validate` → 토스 Billing Auth(`customerKey` 생성) → `POST /memberships {myPetId, membershipMasterId, customerKey, authKey, terms:[{termsHistoryId}]}`. 멤버십은 펫별이라 `myPetId`를 혜택→약관→카드→가입 전체에 관통(마이펫 상세에서 int 변환 전달). `ActiveTerm`에 `termsHistoryId` 추가, `TossBillingTestWebViewScreen`을 `customerKey` 입력+`authKey` 반환으로 개편. 실단말(`R3CR209JAWX`) 검증: guide 바인딩·validate·**토스 Billing Auth 성공(실제 `authKey bln_…` 발급)**·`POST /memberships` **정확 페이로드 호출**까지 앱 흐름 end-to-end 확인. 초기엔 백엔드가 `401 COMMON.NO_ENV(환경변수 없음)`→(env 설정 후)`502 PAYMENT.BILLING_ISSUE_FAILED(BillingKey 발급 실패)` 반환 → **근본 원인은 앱 clientKey↔백엔드 secretKey 상점 불일치**(앱이 공개 샘플 키로 authKey 발급 → 백엔드가 자기 상점 secretKey 로 교환 시도 → 거부). 백엔드가 **`GET /api/v1/payments/config`**(상점 clientKey) 신설, 앱이 Billing Auth 직전 이 키를 받아 사용하도록 전환해 **해결**. 실단말(`R3CR209JAWX`)에서 유효 BIN 카드로 카드 완주 → **`POST /memberships` 200 성공·구독 활성(브론즈 "현재 이용 중"·다음 결제일·월 구독료) 확인**. 가입 성공 시 `petMembershipProvider` 무효화로 마이펫 상세 자동 갱신. 카드 완주는 토스 보안폼 특성상 실기기 수동 입력(유효 BIN 카드)으로만 가능. (다음 단계: Phase 3=카드변경/취소/재구독)
  - **마이펫 상세 멤버십 상태 실연동 (Phase 2)**: 기존 `isPrimary`(대표펫) 기준 하드코딩(무조건 "브론즈 구독중"/미가입)을 **`GET /users/my-pets/{myPetId}/membership`**(`petMembershipProvider`) 실데이터로 교체. 신규 모델 `MembershipInfo`(statusCode ACTIVE/CANCEL_REQUEST·monthlyFee·nextBillingDt·autoRenewYn)·`PetMembershipStatus`. 상태별 렌더 — **미가입**(이용 중인 멤버십 없음 + 혜택 보기), **가입중**(상품명·"현재 이용 중"·다음 결제일·월 구독료·멤버십 관리), **구독취소 예정**(CANCEL_REQUEST/autoRenewYn=N → "구독취소 예정" 배지·"이용 종료일"). 로딩 중 스피너로 미가입 뷰 깜빡임 방지. 실단말(`R3CR209JAWX`)에서 GET 호출 및 **미가입·가입중 상태 정상 렌더 확인**(미가입 펫은 실상태대로 표시, 실 구독 완료 펫은 "브론즈 멤버십·현재 이용 중"·다음 결제일·월 구독료 렌더). ※ 취소예정(CANCEL_REQUEST) 상태는 취소 API(Phase 3) 미구현으로 실기기 미검증(코드는 실데이터 바인딩 완료). 관리/결제내역 버튼은 준비 중 토스트(Phase 3 연결).
  - **멤버십 해지 플로우 (Phase 3a, `MembershipCancelScreen`/`MembershipCancelCompleteScreen`/`MembershipBenefitList`)**: 실단말(`R3CR209JAWX`)에서 구독 펫(TestDog2) 대상 end-to-end 검증 완료 — 구독중 혜택화면(547:12592)·해지화면(547:14070, `cancel-info`로 "28일 남았어요"·이용종료일·**사유 공통코드** 렌더·곰 일러스트)·사유+동의 게이트·확인 다이얼로그(593:11560)·**`POST /cancel` 200 성공**(body `{cancelReasonCodes:["PRICE_BURDEN"], noticeAgreed:true}`)·해지 완료화면(615:10503, 해지신청일 2026.08.10·이용종료일)·마이펫 상세 **"해지 신청" 배지**(1057:32601)·"이용 종료일" 자동 갱신. ※ 초기 body 없는 cancel 이 `401 AUTH.INVALID_PARAMS` → 백엔드가 cancel body 필수(사유코드+동의)로 변경 + `cancel-info` 신설 → 이에 맞춰 사유를 공통코드에서 받아 전송하도록 리팩토링해 해소.
  - **재구독/해지 취소 (Phase 3b)**: 실단말(`R3CR209JAWX`)에서 해지 신청 상태의 TestDog2 대상 검증 완료 — 구독중 혜택화면 "해지 취소하기" 버튼 → 재구독 확인 다이얼로그(900:39130) → **`POST /memberships` 200 성공**(최소 body `{myPetId:20, membershipMasterId:2}`)·완료 토스트(900:39304)·혜택화면 자동 갱신(버튼 "멤버십 해지하기")·마이펫 상세 **"현재 이용 중" 배지·"다음 결제일" 복귀**까지 end-to-end 확인. 구독→해지→재구독→활성 전체 사이클 완성.
  - **펫 정보 수정 완료 토스트 (`MyPetEditScreen`, 기획서 USR_MYP_037_01)**: 펫 관리(수정) 저장 성공 시 "펫 정보가 수정되었어요." 토스트를 표시(기존엔 저장 후 토스트 없이 상세로 복귀 → 기획서 명세 갭). `ToastUtil`이 루트 `Overlay`에 삽입되므로 `context.pop()` 직전에 호출해도 상세 화면 복귀 후까지 노출된다. 실단말(`R3CR209JAWX`) 검증: TestDog2 수정→저장→상세 복귀 후 토스트 정상 노출 확인. ※ 문구는 앱 톤("~되었어요")에 맞춤(기획서 원문 "~되었습니다"와 어미만 상이).
  - **대표펫 해제 차단 (`MyPetEditScreen`)**: 펫 수정 화면의 "대표 펫으로 설정"이 자유 토글이라, **현재 대표펫을 수정하며 체크를 끄면 `representYn:'N'`이 저장돼 대표펫이 0마리**가 되던 문제 수정(백엔드는 대표 최소 1마리를 강제하지 않음 — API로 실측: 14마리 전부 `representYn='N'` 상태 확인). 이 펫이 원래 대표(`_initialIsPrimary==true`)면 체크 해제를 막고 안내 토스트("대표 펫은 최소 한 마리 지정되어야 해요.\n다른 펫을 대표로 설정하면 자동으로 변경됩니다.")를 띄운다 — 대표는 다른 펫을 지정할 때만 이동. 첫 펫 등록(0→1)은 `MyPetHealthFormScreen`에서 이미 `(isFirstPet || _isPrimary)`로 무조건 대표 강제하므로, 이 두 처리로 "등록 펫 ≥1 → 대표 정확히 1마리"가 보장된다. 실단말(`R3CR209JAWX`) 검증: 규규를 대표 지정 후 수정 화면에서 대표 체크 탭 → 해제 안 됨(체크 유지).
  - **펫 등록 완료 요약, 미입력 선택항목 행 숨김 (`MyPetAddCompleteScreen`, 기획서 USR_MYP_035)**: 등록 완료 요약 카드에서 **선택 입력항목(품종·가족이 된 날·체중 측정일)이 미입력이면 항목명 포함 행 전체를 숨긴다**(기존엔 항상 8행, 빈값은 `'-'`·`'믹스'` 표기 → 기획서 명세 갭). 정적 8행 → 동적 리스트로 전환하고 마지막 표시 행에 `isLast`(구분선 제거)를 적용. 실단말(`R3CR209JAWX`) 검증: 품종·가족이 된 날·체중 측정일을 모두 건너뛴 펫(NoBreedTest) 등록 → 완료화면에 입력 5개 항목만 표시되고 3개 행이 숨겨짐 확인(가족이 된 날 건너뛰기도 크래시 없이 정상 등록·숨김).
  - **내 정보 생년월일 read-only 정리 (`MyInfoScreen`, 기획서 USR_MYP_010)**: 명세 "휴대폰 번호 외 수정 불가"에 맞춰 생년월일 행을 **읽기 전용**으로 변경 — 탭 시 휠피커를 여는 `onPressed`를 제거. 저장도 되지 않던 목업 코드(`_customBirthDate` 상태·`_showBirthDatePicker`/`_parseDisplayBirthDate`/`_parseApiBirthDate` 메서드·미사용 `nurim_date_picker` import)를 일괄 정리하고, 표시는 백엔드 값(`_formatApiBirthDate`)만 사용하도록 단순화. 실단말(`R3CR209JAWX`) 검증: 생년월일 탭 시 피커 미노출(휴대폰 번호는 변경 기능 유지).
  - **SNS 회원가입 순서 재정렬 (본인인증 → 약관동의, 기획서·디자인 일치)**: 앱 회원가입 플로우가 `약관동의 → 본인인증` 순이던 것을 기획서·디자인대로 **`본인인증 → 약관동의`**로 재정렬. 새 순서 = SNS로그인 → 본인인증(`verify`) → 약관(`terms`) → 회원정보(`profile`) → 완료. 라우팅 6곳 조정: `auth_start` 소셜로그인 성공→`signupVerify`, `verify` 완료→`signupTerms`, `terms` 다음→`signupProfile`, `verify` 뒤로→취소 게이트(첫 화면), `profile` 뒤로→`signupTerms`. 본인인증은 `signupToken`만 의존(약관 제출과 무관)하고 생년월일을 받아 회원정보에 넘기므로 순서 변경이 백엔드·의존성상 안전. 실단말(`R3CR209JAWX`) 디버그 강제가입으로 검증: 진입→본인인증→약관동의→회원정보 입력(생년월일 자동채움·읽기전용) 순서 확인.
  - **홈 알림(벨) 준비 중 처리 (`MainHeader`)**: 알림 화면(`NotificationScreen`)이 백엔드 알림 API 미제공으로 Mock 데이터라, 홈 우상단 알림 아이콘을 알림 화면 진입(`notificationCenter`) 대신 **"준비 중인 기능입니다." 토스트**로 변경(긴급 아이콘·GNB 탭과 동일 처리). 알림 화면·라우트 코드는 보존(백엔드 알림 API 생기면 재연결), 미사용이 된 `go_router`·`app_routes` import 정리. 실단말(`R3CR209JAWX`) 검증: 벨 탭 → 토스트 노출·화면 이동 없음 확인.
  - **홈 이벤트 배너 준비 중 처리 (`HomeEventCarousel`/`_DesignFriendBanner`)**: 홈 상단 친구초대 이벤트 배너가 백엔드 미연동(친구초대 기능 부재)인데 탭 시 아무 동작 없던 것을, 벨/GNB/설정과 동일하게 **"준비 중인 기능입니다." 토스트**로 처리. 배너 카드를 `GestureDetector`(`HitTestBehavior.opaque`)로 감싸 `ToastUtil` 호출(백엔드 배너 캐러셀 경로 `_ApiBannerCarousel`·`_useApiBanners` 스위치는 불변, 배너 API 생기면 그 경로로 전환). 실단말(`R3CR209JAWX`) 검증: 홈 배너 탭 → "준비 중인 기능입니다." 토스트 노출.
  - **마이페이지를 별도 라우트 push로 전환 (`MyPageScreen`/`HomeScreen`)**: 마이페이지가 `HomeScreen`의 `IndexedStack` 탭(index 5)이라 **하단 GNB가 보이던** 것을, 별도 라우트(`MyPageScreen`, `/my/page`)로 `push`하도록 변경 → 내 정보 관리·결제수단 등 다른 상세 화면과 동일하게 **GNB 미표시**(하위 화면 GNB 숨김은 Material 권장 패턴). `HomeScreen`: 프로필 아이콘 → `context.push(myPage)`, IndexedStack에서 마이페이지 탭 제거(홈~이벤트 5탭만), 로그아웃 로직(`_logout`)을 `MyPageScreen`으로 이전, `initialTab` 범위 클램프(0~4). 펫 등록 완료 이동 `home?tab=5` → `myPage` 라우트. `MyPageScreen` 뒤로가기는 `canPop`이면 `pop`, 아니면 홈으로. 부수 확인: 마이페이지의 `onLogout`은 실제 호출부 없음(로그아웃은 `MyInfoScreen`이 자체 처리)이라 이전 무해, `onBackToHome`은 헤더 뒤로가기에만 사용, 도달 가능한 홈 탭은 0·2뿐(범위 초과 없음). 동작 변화는 "마이페이지가 열 때마다 새로고침"(탭 상태 유지→push 재생성)뿐. 실단말(`R3CR209JAWX`) 검증: 홈→프로필→마이페이지(GNB 없음)→뒤로 홈(GNB 있음), 마이페이지→내 정보 관리→뒤로 마이페이지 복귀.
  - **결제수단 관리 화면 (`PaymentMethodScreen`, USR-PAY-011, Figma 281:16702/282:10032/282:10147/781:54927)**: 백엔드 회원 결제수단 API 신설(2026-08-11)로 언블록된 07_결제수단 관리를 구현. **`GET /api/v1/payment-methods`**(`paymentMethodsProvider`)로 카드 목록(기본 우선·최신 등록순) 표시 — 카드사 아이콘(Figma 로고 5종 다운로드 `assets/images/card_issuers/` + `cardIssuerName` 매핑, 미매핑은 일반 원형 폴백) + 카드명(마스킹 "현대카드(12\*\*)") + 기본 ✓(보라) + 사용제한(빨강, opacity 30%). 카드 탭 → 기본 결제수단 변경(**`PATCH .../{id}/default`**), ⋮ → "카드 삭제하기" → 확인 다이얼로그("카드를 삭제할까요?/삭제 후 다시 사용하려면 재등록이 필요합니다.") → **`DELETE .../{id}`** → "카드가 삭제되었습니다." 토스트 + 목록 갱신. 마이페이지 결제수단 하드코딩 "삼성카드(12\*\*)"를 기본 카드 실데이터(없으면 "미등록")로 교체하고 "변경"을 이 화면으로 연결. "결제카드 추가"(카드 등록 플로우)는 후속으로 분리(현재 준비 중 토스트). 실단말(`R3CR209JAWX`) 검증: 마이페이지 "미등록" 표시·"변경"→화면 진입·빈 상태·"결제카드 추가" 준비중 토스트 확인. ※ 카드 목록/아이콘/삭제/기본변경은 테스트 계정 카드 지갑이 비어 있어(등록 플로우 out-of-scope) 실물 미검증 — analyze + 디자인 대조로 갈음(등록 플로우 구축 후 실물 검증 가능).
  - **결제카드 등록 플로우 + 삭제 아이콘 (`PaymentMethodScreen`)**: 위 결제수단 관리 화면의 후속 — "결제카드 추가"를 실제 등록으로 연결. 토스 Billing Auth(`TossBillingTestWebViewScreen` 재사용, customerKey `pn_user_{ts}`) → **`POST /api/v1/payment-methods {authKey, customerKey}`** → 목록 갱신 + "결제 카드 등록이 완료되었습니다." 토스트. ⋮ 삭제 메뉴 아이콘을 Material `delete_outline`에서 **Figma 트래시 아이콘**(`assets/images/ic_trash_20.svg` — 몸통+뚜껑 2벡터를 20×20 단일 SVG로 합침, stroke `#87909E`, Figma 531:15269)으로 교체하고 텍스트 색 `#51565F` 반영. 실단말(`R3CR209JAWX`) 검증: **등록(토스 카드입력)→목록에 카드 표시→⋮ 삭제하기→확인 다이얼로그→"카드가 삭제되었습니다." 토스트→빈 상태** 전 흐름 확인. ※ 토스 테스트 환경은 `cardIssuerName`을 비워 보내(라벨 "카드(48\*\*)") 카드사 로고 매핑(국민/현대 등)은 폴백만 실증 — 운영 값 확인 후 조정 예정.
  - **마이페이지 결제수단 등록/미등록 분기 (`MyPageView`)**: 마이페이지 결제 수단 영역을 `paymentMethodsProvider` 기준으로 분기 — **등록** 시 기본 카드 라벨(예 "현대카드(12\*\*)") + "변경", **미등록** 시 "결제 수단을 등록해 주세요." + "등록"(둘 다 결제수단 관리 화면으로 이동). 미등록 표시를 디자인(136:13427, USR-MYP-010-Empty)에 맞춰 **이메일 없이 안내문구만** 노출(기존엔 이메일 + "미등록"). 실단말(`R3CR209JAWX`) 검증: 카드 등록/삭제로 두 상태 전환(카드+변경 ↔ 안내문구+등록) 확인.
  - **결제수단 목록 정렬 수정 (`PaymentMethodScreen`)**: 목록을 백엔드 "기본 결제수단 우선" 순서로 그대로 렌더해, 카드를 탭해 기본으로 지정하면 그 카드가 **최상단으로 튀어 오르던** 문제 수정. 클라이언트에서 **최신 등록순(`userPaymentMethodId` 내림차순)으로 안정 정렬** → 탭 시 **그 행에서 ✓ 체크만 이동하고 위치는 고정**된다(기획서 USR_MYP_022 "최신 등록 순으로 정렬"에도 부합). 실단말(`R3CR209JAWX`) 검증: 48\*\*/52\*\* 서로 탭 → ✓만 이동·행 위치 고정 확인(양방향).
  - **멤버십 즉시구독 결제수단 분기 + 브릿지 화면 제거 (`MembershipTermsAgreementScreen`)**: 멤버십 즉시 구독 시 약관 "다음" 이후를 결제수단 유무로 분기 — **등록** 카드는 기본 카드(`userPaymentMethodId`)로 바로 구독, **미등록**은 (디자인에 없는 임의 중간 화면 `MembershipCardRegisterScreen`을 제거하고) 약관 "다음"에서 **바로 토스 카드 등록창**을 띄운다. 토스 `authKey`를 **`POST /api/v1/payment-methods`** 로 지갑에 먼저 등록해 **결제수단 목록에도 카드가 남게** 한 뒤 그 카드로 구독한다. `MembershipRepository.subscribeWithPaymentMethod`(기존 카드 구독, Billing Auth 불필요) 추가, 완료 이동은 `_goComplete`로 공통화, 미사용 브릿지 화면 파일 삭제. 실단말(`R3CR209JAWX`) 검증: 미등록 펫(NoBreedTest) 약관→**토스 직행(중간 화면 없음)**→카드 입력→구독 완료(브론즈 이용 중)→마이페이지 분기 전환(카드+변경)·결제수단 목록 카드 노출까지 end-to-end 확인.
  - **마이펫 목록/마이페이지 멤버십 뱃지 실상태화 (`MyPetListScreen`/`MyPageView`)**: 펫 카드 멤버십 칩이 `representYn`(대표펫 여부)로 결정돼 **대표펫이 아닌 구독 펫이 "멤버십 가입하기"로 잘못 표시**되던 문제 수정(구독 후 목록 갱신 안 됨의 실제 원인). 목록 API(`GET /users/my-pets`)가 펫별 멤버십을 안 주므로, 이미 상세가 쓰는 `petMembershipProvider`(`GET /users/my-pets/{myPetId}/membership`, 펫당 1콜 — 리워드 요약과 동일 per-pet 패턴)를 카드마다 `watch`해 `PetMembershipStatus.petCardChipLabel` 확장으로 칩 라벨 파생(가입=티어명 "브론즈 멤버십"→"브론즈"·미가입="멤버십 가입하기"·로딩="-"). 목록 새로고침·상세 복귀·마이페이지 refresh 시 `petMembershipProvider`(family 전체) 무효화로 갱신. 대표펫 ★ 뱃지(`isPrimary`)는 유지. 실단말(`R3CR209JAWX`) 검증: NoBreedTest 구독 후 목록/마이페이지가 "멤버십 가입하기"→"브론즈"로 갱신, 펫별 매핑 정확(호호 다음결제일 09.07 vs NoBreedTest 09.11 — index 어긋남 없음).
  - **해지/재구독 확인 다이얼로그 "취소·닫기" 먹통 수정 (`EdgeButtonDialog` 호출부)**: `EdgeButtonDialog`의 취소 버튼은 `onCancel ?? 기본 pop` 구조라 **빈 콜백 `onCancel: () {}`을 넘기면 pop도 콜백도 하지 않아** 취소가 먹통이 됨(confirm 버튼은 항상 pop → 비대칭). 멤버십 **해지 확인**(`membership_cancel_screen`, "취소")·**재구독 확인**(`membership_benefits_screen`, "닫기") 두 곳의 빈 `onCancel: () {}`을 제거해 위젯 기본 dismiss에 맡김. (위젯을 "항상 자동 pop"으로 바꾸면 onCancel 내부에서 직접 pop하는 정상 호출부 verify/camera/terms/qna가 더블 팝 회귀 → 위젯 불변, 버그 호출부만 수정). 실단말(`R3CR209JAWX`) 검증: 재구독 "닫기" → 다이얼로그 닫히고 재구독 미실행·상태 유지(해지 확인 "취소"도 동일 위젯·동일 수정).
  - **마이펫 카드 "멤버십 가입하기" 칩 → 멤버십 혜택 화면 연결 (`NurimPetCard`/`MyPetListScreen`/`MyPageView`)**: 화살표(`>`)로 CTA처럼 보이던 "멤버십 가입하기" 칩에 **핸들러가 없어 탭해도 아무 동작 안 하던** 문제 수정(화살표는 "가입하기"에만 있고 "브론즈" 배지엔 없어 원래 탭 유도 CTA로 설계됨). `_MembershipChip`을 **가입하기 상태일 때만** 탭 가능하게(`onTap`, 브론즈 배지는 비탭 유지), `NurimPetCardData.onMembershipJoinTap` 콜백 추가. 목록/마이페이지에서 해당 펫 `myPetId`로 `MembershipBenefitsScreen` push(펫 상세 "멤버십 혜택 보기"와 동일 `MaterialPageRoute`+`routeName` 패턴 → 구독완료 popUntil 정상, 복귀 시 `myPetsListProvider`·`petMembershipProvider` 무효화로 칩 갱신). 카드 이름/아바타 탭은 기존대로 펫 상세. 실단말(`R3CR209JAWX`) 검증: "교"(미가입) 칩 탭 → 혜택 화면 이동, "브론즈" 배지 탭 → 반응 없음.
  - **멤버십 구독 "구독하기" 확인 화면 (`SubscribeConfirmScreen`, Figma 547:13693, USR-MBS-014)**: 카드 선택 후 곧바로 구독하던 것을, **결제 직전 확인 화면**을 거쳐 "N원 결제하기"로 최종 결제하도록 변경(사용자 요청). 구독 정보(멤버십명+"매월 신용카드 자동결제"+ⓘ힌트)·결제 정보(월 이용료·부가세·결제 방식·다음 결제일·총 결제 금액 보라)·결제 수단(`CardIssuerIcon`+`cardLabel`, `>` 탭 시 카드 선택 시트 재오픈으로 변경)·"멤버십 이용약관에 동의 >"(약관 목록 바텀시트)·결제 시 유의사항·전체폭 결제 버튼. **레이아웃**: 디자인의 흰 섹션 + 회색 구분 배경을 반영해 `Scaffold` 배경을 `AppColors.sectionGap`(신규 `#EDF0F4`, 디자인 토큰 `#F4F6F8`이 기기에서 흰색과 구분 안 돼 살짝 진하게)으로 두고 각 섹션을 흰 블록으로 분리. **약관 링크**: 기획서·디자인 모두 이 인터랙션 미정(디자인 프레임명 "…신용카드 등록 전(보류)", "이용약관에 동의"는 텍스트+화살표만) → 협의로 약관 목록 바텀시트(구독 이용약관/개인정보 처리방침, 약관 동의 화면과 **동일한** `subscriptionTermsProvider` 2건, 각 상세 HTML) 결정. **데이터**: 백엔드 미제공분(부가세·결제 전 다음 결제일)은 부가세=`monthlyFee×10/110`(예 10,000→909원)·다음 결제일=오늘+1개월으로 표기(디자인 목업 15,000/5,000/2026.06.30은 서로 불일치하는 플레이스홀더 → 실 `monthlyFee` 기준 자기일관 바인딩). 실단말(`R3CR209JAWX`) 검증: 약관→카드 선택→확인 화면(섹션 분리·전체폭 버튼)→약관 목록 시트(약관 2건·상세 HTML·상세→시트 복귀)→카드 변경(48**→52**)→결제하기→결제 완료(선택 카드 KB국민카드(52**) 반영)·목록 브론즈 갱신. ※ 결제 수단 카드가 "카드(48**)" 폴백으로 보이는 건 `GET /payment-methods` 목록이 테스트 환경서 `cardIssuerName`을 비워 주기 때문(완료 화면은 상세 API라 "KB국민카드"까지 표시) — 운영 값 확인 후 자동 해소.
  - **로그인 디버그 도구 빌드 플래그 (`AuthStartScreen`)**: 로그인 화면의 개발용 버튼([테스트] 신규 가입 흐름 강제진입 · 클립보드 토큰 주입)을 `kDebugMode`(디버그 빌드면 항상 노출) 대신 **dart-define 플래그**(`const _kShowLoginDebug = bool.fromEnvironment('SHOW_LOGIN_DEBUG')`, 기본 `false`=숨김)로 게이트. 평소엔 숨겨지고, 필요할 때만 `--dart-define=SHOW_LOGIN_DEBUG=true` 로 빌드하면 노출된다(버튼·메서드는 보존). 실단말 검증: 플래그 없이 빌드 → 로그인 화면에 디버그 버튼 미노출.
  - **하단 GNB 아이콘 피그마 반영 (`CustomGnb`, Figma 339:20717)**: 참조 경로(`assets/icons/`)가 없어 Material 폴백 아이콘이 그려지던 문제 수정. 피그마 SVG 10종을 `assets/images/gnb/`에 추가하고 `SvgPicture.asset`으로 교체.
  - **펫 카드 아이콘 피그마 반영 (`NurimPetCard`, Figma 215:6440)**: 멤버십·리워드·대표펫 배지·화살표 아이콘이 `CustomPainter` 손그림이라 디자인과 달랐던 문제 수정. 피그마 SVG(`ic_crown_20`/`ic_coin_20`/`ic_favorite`/`ic_arrow_right_24`)로 교체하고 손그림 클래스 제거.
  - **촬영 펫 선택 화면 대표펫 배지 (`PetSelectCard`, Figma 559:7019)**: 촬영 펫 목록 API가 대표펫 여부를 주지 않아 배지가 표시되지 않던 문제 수정 — 마이펫 목록(`representYn`)을 함께 조회해 판정하고, 배지·화살표를 피그마 SVG로 교체.
  - **멤버십 혜택 아이콘·화살표 피그마 반영 (`MembershipBenefitList`/`MembershipBenefitsScreen`, Figma 534:20157)**: 혜택 3종 아이콘(Material) → 피그마 SVG(`ic_benefit_{gift,coin,medal}_24.svg`)로 교체하고, 구독 버튼·유의사항 접이식 화살표도 피그마 chevron으로 교체(유의사항 아이콘 색 `#51565F` → `#909AA9` 교정).
  - **내 정보 화면 공용 컴포넌트 정리 (`MyInfoScreen`)**: 커스텀 로그아웃 다이얼로그를 공용 `EdgeButtonDialog`로, 상세주소 입력 시트의 자체 헤더를 공용 `PopupHeader`로 교체. 행·주소 카드 화살표는 피그마 `Icon/ArrowRight/16`으로 통일.
  - **공용 헤더 뒤로가기 아이콘 통일 (`NurimPageHeader`/`PopupHeader`)**: Material 아이콘(`arrow_back`·`arrow_back_ios_new`)을 피그마 `Icon/ArrowLeft/24`(`ic_arrow_left_24.svg`)로 교체 — 앱 전체 뒤로가기 모양이 동일해진다.
  - **카메라 촬영 후 하단 버튼 피그마 반영 (`CameraButtonBar`, Figma 573:12016)**: 문구를 `취소`·`저장` → **`다시 촬영`·`저장하기`**로, 좌측 아이콘을 Material `close` → 피그마 `Icon/Refresh/24`로 교체(동작은 원래 재촬영이라 변경 없음).
  - **홈 미션 카드 피그마 반영 (`NurimCardBannerSmall`, Figma 132:9673/116:8397)**: 화살표가 카드 오른쪽 끝으로 밀려 있던 배치를 문구 바로 뒤로 옮기고 Material 아이콘(12px) → 피그마 chevron SVG(16px `#909AA9`)로 교체. 카드 높이 174→178, 카드 간격 11→12, 섹션 하단 여백 28→24로 정정.
  - **마이펫 상세 아이콘·간격 피그마 반영 (`MyPetDetailScreen`/`PetInfoDetail`, Figma 231:19551·541:9055)**: 구독 중 상태의 대표펫 배지(Material 별 → `ic_favorite.svg`)·"브론즈" 앞 아이콘(금색 원+별 → 보라 크라운 `ic_crown_24.svg`)·결제/리워드 내역 화살표를 피그마 SVG로 교체하고, 미가입 상태의 타이틀↔안내 간격(40→24)과 버튼 화살표를 정정.
  - **마이펫 리스트·편집 화면 피그마 반영 (`MyPetListScreen`/`NurimPetCard`, Figma 204:7650·215:10463·215:10701)**: 타이틀 색상(전체·개수·편집)과 여백을 디자인값으로 정정하고, 펫 카드 높이 204→192·편집 모드 라디오 상단 정렬·선택 카드 보더 1.5→1.0·비활성 버튼 텍스트 색을 맞췄다.
  - **마이펫 추가(종류 선택) 화면 피그마 반영 (`MyPetAddScreen`, Figma 215:11766·215:12157)**: 선택 카드 높이 176→156, 선택 보더 1.5→1.0, 질문 텍스트 상단 여백 20→16으로 정정.
  - **마이펫 추가 플로우·나이 시트 피그마 반영 (Figma 217:4465·227:15114·227:15328·228:18885·226:14092)**: 프로필·이야기·건강·완료 4단계의 제목 여백/간격과 아이콘(셀렉트 화살표·달력·카메라)을 피그마 SVG로 맞추고, 선택 상태 색(성별·중성화 `#30343C`, 대표펫 체크)을 정정. 나이 선택 바텀시트도 여백·타이포·행 구분선·체크 표시 방식을 디자인대로 재구성.
- **플랫폼 빌드/배포**: Android 실단말 디버그 실행(`SM G991N`, `R3CR209JAWX`) 및 iOS 빌드 확인(`flutter build ios --no-codesign`) 완료. Firebase App Distribution(`web3-petnurim`) 테스트 빌드 배포. 배포 절차·초기 세팅(macOS 처음 시작 기준)은 [`docs/firebase-app-distribution.md`](docs/firebase-app-distribution.md) 참고. **로그인 디버그 도구 노출 빌드**: `flutter build apk --debug --dart-define=SHOW_LOGIN_DEBUG=true --dart-define-from-file=dart_defines.json`


