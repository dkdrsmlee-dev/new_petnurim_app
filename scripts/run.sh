#!/usr/bin/env bash
#
# flutter 명령을 dart-define(네이버 Client Secret 등)과 함께 실행하는 래퍼.
#
# 시크릿은 저장소에 커밋하지 않고 dart_defines.json(.gitignore 처리됨)에 둡니다.
# 최초 1회 아래처럼 예시 파일을 복사해 실제 값을 채워주세요:
#     cp dart_defines.example.json dart_defines.json
#
# 사용법:
#   ./scripts/run.sh                      # flutter run (기본, 기기에서 실행)
#   ./scripts/run.sh build apk --debug    # flutter build apk --debug
#   ./scripts/run.sh build apk --release
#   ./scripts/run.sh <임의의 flutter 명령/옵션...>
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFINES="$ROOT/dart_defines.json"

if [[ ! -f "$DEFINES" ]]; then
  echo "⚠️  dart_defines.json 파일이 없습니다."
  echo "    예시 파일을 복사해 실제 값을 채워주세요:"
  echo "      cp \"$ROOT/dart_defines.example.json\" \"$DEFINES\""
  exit 1
fi

# 인자가 없으면 기본으로 run
if [[ $# -eq 0 ]]; then
  set -- run
fi

cd "$ROOT"
echo "▶ flutter $* --dart-define-from-file=dart_defines.json"
exec flutter "$@" --dart-define-from-file="$DEFINES"
