#!/bin/bash
# SessionStart hook for Claude Code cloud sessions: installs the Flutter SDK
# pinned in example/pubspec.yaml and fetches pub dependencies so
# `dart format`, `flutter analyze` and `flutter test` work out of the box.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

# environment.flutter in example/pubspec.yaml, the version CI installs.
FLUTTER_VERSION="$(sed -n 's/^  flutter: *"\{0,1\}\([0-9][0-9.]*\)"\{0,1\}[[:space:]]*$/\1/p' \
  "$PROJECT_DIR/example/pubspec.yaml" | head -n1)"
if [ -z "$FLUTTER_VERSION" ]; then
  echo "No exact environment.flutter in example/pubspec.yaml" >&2
  exit 1
fi
FLUTTER_ROOT="$HOME/flutter-sdk/$FLUTTER_VERSION"

if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
  echo "Installing Flutter $FLUTTER_VERSION into $FLUTTER_ROOT" >&2
  mkdir -p "$(dirname "$FLUTTER_ROOT")"
  tmp="$(mktemp -d)"
  curl -fsSL --retry 4 \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "$tmp"
  rm -rf "$FLUTTER_ROOT"
  mv "$tmp/flutter" "$FLUTTER_ROOT"
  rmdir "$tmp"
fi

# The SDK checkout is owned by a different uid than git sometimes expects.
git config --global --get-all safe.directory | grep -qxF "$FLUTTER_ROOT" \
  || git config --global --add safe.directory "$FLUTTER_ROOT"

export PATH="$FLUTTER_ROOT/bin:$PATH"
export FLUTTER_SUPPRESS_ANALYTICS=true
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export PATH=\"$FLUTTER_ROOT/bin:\$PATH\""
    echo "export FLUTTER_SUPPRESS_ANALYTICS=true"
  } >> "$CLAUDE_ENV_FILE"
fi

flutter --disable-analytics >/dev/null 2>&1 || true
flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version >&2

cd "$PROJECT_DIR"
flutter pub get >&2
