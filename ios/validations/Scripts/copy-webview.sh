#!/usr/bin/env bash
# Copies the Vue sample app build into the SampleApp bundle.
# When run from Xcode (post-build): copies into the .app bundle so the app finds webview at runtime.
# Run manually: populates SampleApp/Resources/webview for reference.
# Requires: build Vue first: cd sample-apps/validations-sdk-sample-app && npm run build

set -e

# Xcode runs build scripts with a minimal PATH. When running from Xcode,
# always inherit the full PATH from the user's login shell so node/npm are
# found regardless of how they were installed (Homebrew, nvm, fnm, volta, etc.).
# This also handles cases where Xcode finds a broken npm installation before
# the correct one (e.g. a Homebrew node without its npm module).
if [ -n "${SRCROOT:-}" ] || ! command -v npm &>/dev/null; then
  USER_PATH=$("${SHELL:-/bin/zsh}" -ilc 'echo $PATH' 2>/dev/null) && export PATH="$USER_PATH"
fi

# Use SRCROOT when run from Xcode
if [ -n "${SRCROOT:-}" ]; then
  PROJECT_DIR="$SRCROOT"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
ROOT_DIR="$(cd "$PROJECT_DIR/../.." && pwd)"
VUE_APP="$ROOT_DIR/sample-apps/validations-sdk-sample-app"

if [ ! -d "$VUE_APP" ]; then
  echo "warning: Vue app not found at $VUE_APP. SampleApp will need webview assets."
  exit 0
fi

# Build Vue app if dist is missing, or if .env.local changed
NEED_BUILD=false
if [ ! -f "$VUE_APP/dist/index.html" ]; then
  NEED_BUILD=true
  echo "Vue dist missing, will build"
elif [ -f "$VUE_APP/.env.local" ] && [ "$VUE_APP/.env.local" -nt "$VUE_APP/dist/index.html" ]; then
  NEED_BUILD=true
  echo ".env.local is newer than dist, rebuilding to pick up VITE_TRUORA_API_KEY"
fi

if [ "$NEED_BUILD" = true ]; then
  if command -v npm &> /dev/null; then
    echo "Building Vue sample app..."
    (cd "$VUE_APP" && npm ci --no-audit --no-fund 2>/dev/null || npm install --no-audit --no-fund)
    (cd "$VUE_APP" && npm run build)
  else
    echo "warning: npm not found. Run: cd sample-apps/validations-sdk-sample-app && npm run build"
    exit 0
  fi
fi

# When built from Xcode: copy directly into the app bundle (post-build phase)
if [ -n "${BUILT_PRODUCTS_DIR:-}" ] && [ -n "${FULL_PRODUCT_NAME:-}" ]; then
  APP_BUNDLE="$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME"
  WEBVIEW_DST="$APP_BUNDLE/webview"
  mkdir -p "$WEBVIEW_DST"
  cp -R "$VUE_APP/dist/"* "$WEBVIEW_DST/"
  echo "Copied WebView assets into app bundle: $WEBVIEW_DST"
else
  # Manual run: copy to Resources so project stays in sync
  WEBVIEW_DST="$PROJECT_DIR/SampleApp/Resources/webview"
  mkdir -p "$WEBVIEW_DST"
  cp -R "$VUE_APP/dist/"* "$WEBVIEW_DST/"
  echo "Copied WebView assets to $WEBVIEW_DST"
fi
