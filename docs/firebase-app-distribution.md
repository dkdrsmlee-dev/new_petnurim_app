# Firebase App Distribution 배포 가이드 (new_petnurim_app)

테스터에게 테스트 빌드를 배포하는 절차. **현재 프로젝트 실제 설정 기준.**

> ⚠️ **이 문서는 macOS 환경 기준입니다.** (셸: `zsh`/`bash`, 경로 구분자 `/`, Firebase CLI: Homebrew 설치 `/opt/homebrew/bin/firebase`)
> - **iOS(`.ipa`) 빌드·배포는 macOS + Xcode에서만 가능**합니다(Windows/Linux 불가).
> - Windows에서 Android만 배포한다면 명령은 거의 동일하나, 경로 구분자(`\`)·줄바꿈(`^`)·셸 문법만 환경에 맞게 바꾸면 됩니다.

## 프로젝트 정보 (실제값)

| 항목 | 값 |
|---|---|
| Firebase 프로젝트 ID | `web3-petnurim` |
| 프로젝트 번호 | `840547817589` |
| **Android 앱 ID** | `1:840547817589:android:42f6129b6888888d59803c` |
| **iOS 앱 ID** | `1:840547817589:ios:ac9f954d4e910b0d59803c` |
| 패키지/번들 ID | `com.dkdr.newpetnurim` |
| 앱 버전 | `1.0.0+1` (`pubspec.yaml`의 `version`) |
| Firebase 설정 파일 | `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` (이미 커밋됨) |

> 위 값들은 `firebase.json`, `google-services.json`에 들어 있어 별도 조회 없이 그대로 사용하면 된다.

---

## 처음 시작하는 사람을 위한 macOS 초기 세팅 (아무것도 없는 상태부터)

> 새 맥에서 처음 세팅하는 경우 아래를 **순서대로** 진행한다. 이미 설치된 항목은 건너뛰면 된다.
> Android만 배포하면 `4번(Xcode)`은 건너뛰어도 되고, iOS만 배포하면 `5번(Android)`을 건너뛰어도 된다.

### 1. Homebrew (macOS 패키지 매니저)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
- 설치 후 **PATH 등록 안내가 출력**된다(Apple Silicon 기준). 안내대로 실행:
  ```bash
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ```
- 확인: `brew --version`

### 2. Git & Xcode Command Line Tools
```bash
xcode-select --install     # 커맨드라인 도구(컴파일러·git 등)
git --version              # 확인
```

### 3. Flutter SDK
```bash
brew install --cask flutter     # 방법 A (권장)
# (대안) 공식 zip 받아 ~/flutter 에 풀고 PATH 등록:
#   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc && source ~/.zshrc
flutter --version               # 확인
```

### 4. iOS 도구 — **iOS 배포 시에만** (macOS 전용)
1. **Xcode** — App Store에서 설치(용량 큼·오래 걸림).
2. 최초 실행/도구 경로/라이선스:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   sudo xcodebuild -license accept
   ```
3. **CocoaPods**:
   ```bash
   brew install cocoapods
   ```

### 5. Android 도구 — **Android 배포 시에만**
1. **Android Studio**(SDK·platform-tools 포함):
   ```bash
   brew install --cask android-studio
   ```
   실행 → 초기 마법사에서 **Android SDK / Platform-Tools / Command-line Tools** 설치.
2. **라이선스 동의**:
   ```bash
   flutter doctor --android-licenses   # 나오는 항목 모두 y
   ```
3. **adb PATH**(실단말에 직접 설치·디버그 시):
   ```bash
   echo 'export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"' >> ~/.zshrc
   source ~/.zshrc
   adb --version   # 확인
   ```

### 6. Firebase CLI
```bash
brew install firebase-cli        # 권장(Node 불필요·독립 실행)
# (대안) npm 사용 시 Node 먼저:  brew install node && npm install -g firebase-tools
firebase --version               # 확인 (15.x)
```

### 7. 전체 점검 — `flutter doctor`
```bash
flutter doctor
```
- Flutter / (iOS 시 Xcode) / (Android 시 Android toolchain) 항목이 **[✓]** 인지 확인. `[!]`가 있으면 안내대로 보완.

### 8. 프로젝트 받기 + 의존성
```bash
git clone <저장소 URL>            # 예: dkdrsmlee-dev/new_petnurim_app
cd new_petnurim_app
flutter pub get
```

### 9. `dart_defines.json` 생성 (네이버 시크릿)
- **gitignore돼 있어 리포에 없다.** 담당자에게 시크릿을 받아 프로젝트 루트에 생성:
  ```json
  { "NAVER_CLIENT_SECRET": "<발급받은 시크릿>" }
  ```
  > 없으면 네이버 로그인이 빠진 빌드가 만들어진다. **절대 커밋 금지.**

### 10. Firebase 로그인 (+ 프로젝트 권한)
```bash
firebase login          # 브라우저로 로그인
firebase login:list     # 로그인 계정 확인
```
- `web3-petnurim` 프로젝트에 **App Distribution 권한**이 있어야 배포 가능. 없으면 프로젝트 관리자에게 초대 요청.

여기까지 되면 아래 **Android/iOS 배포**로 진행한다.

---

## Android 배포 (가장 흔한 경로)

### 1) 빌드

```bash
# 디버그 APK (테스트용, 서명 불필요 · 용량 큼 ~216MB)
flutter build apk --debug --dart-define-from-file=dart_defines.json

# 또는 릴리스 APK (용량 작음 · 서명 설정 필요 — 아래 '릴리스 서명' 참고)
flutter build apk --release --dart-define-from-file=dart_defines.json
```

- 산출물: `build/app/outputs/flutter-apk/app-debug.apk` (또는 `app-release.apk`)
- **`--dart-define-from-file=dart_defines.json` 필수** — 빼먹으면 네이버 시크릿 미주입.

### 2) 배포

```bash
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-debug.apk \
  --app 1:840547817589:android:42f6129b6888888d59803c \
  --release-notes "이번 빌드 변경 요약" \
  --testers "dkdrsmlee@dkdoctor.kr"
```

- `--app` : 위의 **Android 앱 ID** (프로젝트는 앱 ID에서 자동 인식. 명시하려면 `--project web3-petnurim` 추가)
- 테스터 지정 방법 (택1):
  - `--testers "a@x.com,b@x.com"` — 이메일 직접 나열
  - `--testers-file testers.txt` — 파일(줄바꿈/콤마 구분)
  - `--groups "그룹별칭"` — 콘솔에서 만든 테스터 그룹 별칭
- 릴리스 노트 파일로: `--release-notes-file release-notes.txt`

배포되면 테스터에게 초대 메일이 가고, **App Tester 앱** 또는 링크로 설치한다.

### 3) 확인
- Firebase Console → **App Distribution** → 릴리스 목록에서 버전/테스터/설치 상태 확인.

---

## iOS 배포 (서명 필요, 더 복잡)

iOS는 `.ipa`가 필요하고 **Apple 개발자 계정 서명/프로비저닝**이 있어야 한다.

```bash
# 서명 프로비저닝이 구성돼 있어야 함 (Xcode / 수동 export)
flutter build ipa --release --dart-define-from-file=dart_defines.json
# 산출물: build/ios/ipa/*.ipa

firebase appdistribution:distribute \
  build/ios/ipa/new_petnurim_app.ipa \
  --app 1:840547817589:ios:ac9f954d4e910b0d59803c \
  --release-notes "iOS 테스트 빌드" \
  --testers "dkdrsmlee@dkdoctor.kr"
```

- 테스터 기기의 **UDID가 프로비저닝 프로파일에 등록**돼 있어야 설치 가능(Ad Hoc). 미등록이면 TestFlight를 고려.
- 서명 미구성 상태 확인만 하려면: `flutter build ios --no-codesign` (배포용 아님).

---

## 참고 / 팁

- **디버그 vs 릴리스**: 빠른 내부 테스트는 디버그 APK(서명 불필요)가 간편. 용량·성능 실측/외부 배포는 릴리스 권장.
- **릴리스 서명(Android)**: `android/key.properties` + keystore 구성 후 `android/app/build.gradle`의 signingConfig 연결 필요(현재 릴리스 서명 미구성 시 릴리스 APK 빌드 실패할 수 있음 → 우선 디버그로 배포).
- **콘솔 수동 업로드**: CLI 대신 Firebase Console → App Distribution → "배포"에서 APK 드래그&드롭도 가능.
- **버전 올리기**: `pubspec.yaml`의 `version: 1.0.0+1`에서 빌드번호(`+1`)를 올리면 App Distribution에서 새 릴리스로 구분된다.
- **CI 자동화(선택)**: `firebase login:ci`로 토큰 발급 후 `FIREBASE_TOKEN` 환경변수 + `--token`으로 무인 배포 가능.

## 자주 겪는 문제

| 증상 | 원인/해결 |
|---|---|
| 네이버 로그인 안 됨 | 빌드 시 `--dart-define-from-file=dart_defines.json` 누락 → 재빌드 |
| `Failed to authenticate` | `firebase login` 재로그인 또는 프로젝트 권한 없음 |
| 앱 ID 오류 | `--app`에 **Android/iOS 앱 ID를 정확히** (위 표) 사용 |
| 테스터에게 메일 안 옴 | 스팸함 확인 / 콘솔에서 테스터 상태 확인 / 그룹 별칭 오타 |
| iOS 설치 실패 | 기기 UDID 미등록(Ad Hoc) → 프로비저닝에 UDID 추가 후 재빌드 |

---

## 빠른 요약 (Android 디버그 배포)

```bash
firebase login   # (최초 1회)
flutter build apk --debug --dart-define-from-file=dart_defines.json
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-debug.apk \
  --app 1:840547817589:android:42f6129b6888888d59803c \
  --release-notes "변경 요약" \
  --testers "dkdrsmlee@dkdoctor.kr"
```
