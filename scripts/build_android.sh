#!/usr/bin/env bash
# Interactive Android APK / AAB builder.
# Bumps pubspec.yaml minor version + build number, then builds the selected flavor.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PUBSPEC="$ROOT/pubspec.yaml"
GRADLE="$ROOT/android/app/build.gradle.kts"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${CYAN}▸${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

choose() {
  local prompt="$1"
  shift
  local options=("$@")
  local choice
  echo ""
  echo -e "${BOLD}${prompt}${NC}"
  local i
  for i in "${!options[@]}"; do
    printf "  %d) %s\n" $((i + 1)) "${options[$i]}"
  done
  while true; do
    read -r -p "Enter choice [1-${#options[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#options[@]})); then
      CHOSEN="${options[$((choice - 1))]}"
      return 0
    fi
    echo "Invalid choice. Pick a number between 1 and ${#options[@]}."
  done
}

camel_to_snake() {
  echo "$1" | sed -E 's/([A-Z])/_\1/g' | tr '[:upper:]' '[:lower:]'
}

capitalize() {
  local value="$1"
  echo "$(tr '[:lower:]' '[:upper:]' <<< "${value:0:1}")${value:1}"
}

discover_flavors() {
  if [[ ! -f "$GRADLE" ]]; then
    fail "Android Gradle file not found: $GRADLE"
  fi
  sed -n '/productFlavors[[:space:]]*{/,/^    }/p' "$GRADLE" \
    | grep -E 'create\("[^"]+"\)' \
    | sed -E 's/.*create\("([^"]+)"\).*/\1/'
}

flavor_label() {
  local flavor="$1"
  local name
  name="$(sed -n "/create(\"${flavor}\")/,/^[[:space:]]*}/p" "$GRADLE" \
    | grep -E 'resValue\("string", "app_name"' \
    | head -1 \
    | sed -E 's/.*"app_name", "([^"]+)".*/\1/' || true)"
  if [[ -z "$name" ]]; then
    name="$flavor"
  fi
  if [[ "$flavor" == "localLendingHub" ]]; then
    echo "${name} (default) [${flavor}]"
  else
    echo "${name} [${flavor}]"
  fi
}

read_version() {
  grep -E '^version:' "$PUBSPEC" | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'"
}

next_version() {
  local current="$1"
  local name="${current%%+*}"
  local build="${current##*+}"
  if [[ "$current" != *"+"* ]] || [[ -z "$build" ]]; then
    fail "pubspec.yaml version must be MAJOR.MINOR.PATCH+BUILD (got: ${current})"
  fi
  local major minor patch
  IFS='.' read -r major minor patch <<< "$name"
  if [[ -z "$major" || -z "$minor" || -z "$patch" ]]; then
    fail "Could not parse semantic version from: ${current}"
  fi
  minor=$((minor + 1))
  patch=0
  build=$((build + 1))
  echo "${major}.${minor}.${patch}+${build}"
}

write_version() {
  local new_version="$1"
  local tmp
  tmp="$(mktemp)"
  awk -v new_version="$new_version" '
    BEGIN { replaced = 0 }
    /^version:/ && replaced == 0 {
      print "version: " new_version
      replaced = 1
      next
    }
    { print }
  ' "$PUBSPEC" > "$tmp"
  mv "$tmp" "$PUBSPEC"
}

output_path() {
  local format="$1"
  local mode="$2"
  local flavor="$3"
  if [[ "$format" == "apk" ]]; then
    echo "build/app/outputs/flutter-apk/app-${flavor}-${mode}.apk"
  else
    local variant="${flavor}$(capitalize "$mode")"
    echo "build/app/outputs/bundle/${variant}/app-${flavor}-${mode}.aab"
  fi
}

echo -e "${BOLD}Android build${NC}"
echo "Project: ${ROOT}"

CURRENT_VERSION="$(read_version)"
[[ -n "$CURRENT_VERSION" ]] || fail "Could not read version from pubspec.yaml"
NEXT_VERSION="$(next_version "$CURRENT_VERSION")"

FLAVORS=()
while IFS= read -r flavor; do
  [[ -n "$flavor" ]] && FLAVORS+=("$flavor")
done < <(discover_flavors)
((${#FLAVORS[@]} > 0)) || fail "No product flavors found in android/app/build.gradle.kts"

FLAVOR_LABELS=()
for flavor in "${FLAVORS[@]}"; do
  FLAVOR_LABELS+=("$(flavor_label "$flavor")")
done

choose "Artifact format" "apk" "aab"
FORMAT="$CHOSEN"
if [[ "$FORMAT" == "aab" ]]; then
  BUILD_TARGET="appbundle"
else
  BUILD_TARGET="apk"
fi

choose "Build mode" "release" "debug"
MODE="$CHOSEN"

choose "Flavor" "${FLAVOR_LABELS[@]}"
FLAVOR_LABEL="$CHOSEN"
FLAVOR="${FLAVOR_LABEL##*\[}"
FLAVOR="${FLAVOR%\]}"

SNAKE="$(camel_to_snake "$FLAVOR")"
TARGET="lib/main_${SNAKE}.dart"
[[ -f "$TARGET" ]] || fail "Flavor entrypoint not found: ${TARGET}"

if [[ "$FORMAT" == "aab" && "$MODE" == "debug" ]]; then
  warn "App Bundles are usually built as release for Play Store."
fi

echo ""
echo -e "${BOLD}Summary${NC}"
echo "  Version : ${CURRENT_VERSION}  →  ${NEXT_VERSION}  (minor + build)"
echo "  Format  : ${FORMAT}"
echo "  Mode    : ${MODE}"
echo "  Flavor  : ${FLAVOR}"
echo "  Target  : ${TARGET}"
echo ""
read -r -p "Proceed with version bump and build? [Y/n] " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  warn "Cancelled."
  exit 0
fi

info "Bumping version in pubspec.yaml"
write_version "$NEXT_VERSION"
ok "Version is now $(read_version)"

BUILD_CMD=(flutter build "$BUILD_TARGET" "--${MODE}" --flavor "$FLAVOR" -t "$TARGET")
info "Running: ${BUILD_CMD[*]}"
"${BUILD_CMD[@]}"

ARTIFACT="$(output_path "$FORMAT" "$MODE" "$FLAVOR")"
echo ""
if [[ -f "$ARTIFACT" ]]; then
  ok "Build complete: ${ARTIFACT}"
  if command -v open >/dev/null 2>&1; then
    open "$(dirname "$ARTIFACT")"
  fi
else
  warn "Build finished, but expected artifact was not at: ${ARTIFACT}"
  warn "Check Flutter's output above for the actual path."
fi
