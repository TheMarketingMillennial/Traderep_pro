#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# build_with_secrets.sh — TradeRep Pro
#
# Loads .env and runs a Flutter build with all secrets injected as
# --dart-define flags. The values never touch the source code.
#
# Usage:
#   chmod +x scripts/build_with_secrets.sh
#   ./scripts/build_with_secrets.sh web          # flutter build web --release
#   ./scripts/build_with_secrets.sh apk          # flutter build apk --release
#   ./scripts/build_with_secrets.sh appbundle    # flutter build appbundle --release
#   ./scripts/build_with_secrets.sh run          # flutter run (debug, web)
#
# Prerequisites:
#   1. cp .env.example .env
#   2. Fill in real values in .env
#   3. Never commit .env (it is in .gitignore)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ENV_FILE="$(dirname "$0")/../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌  .env not found at $ENV_FILE"
  echo "    Copy .env.example → .env and fill in your values."
  exit 1
fi

# Load .env — skip comments and blank lines
set -a
# shellcheck disable=SC1090
source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
set +a

# Production Railway backend — used as default for all server URLs
PROD_RAILWAY="https://traderep-server-production.up.railway.app"

# Build the --dart-define chain from loaded env vars
DEFINES=(
  # ── Firebase ────────────────────────────────────────────────────────────────
  "--dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY}"
  "--dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"
  "--dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}"
  "--dart-define=FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN}"
  "--dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}"
  "--dart-define=FIREBASE_DATABASE_URL=${FIREBASE_DATABASE_URL:-}"
  "--dart-define=FIREBASE_APP_ID_WEB=${FIREBASE_APP_ID_WEB}"
  "--dart-define=FIREBASE_APP_ID_ANDROID=${FIREBASE_APP_ID_ANDROID}"
  "--dart-define=FIREBASE_APP_ID_IOS=${FIREBASE_APP_ID_IOS:-}"
  # ── Railway Backend (all four point to the same production server) ──────────
  # Override individually in .env only if running a split-service setup.
  "--dart-define=AI_SERVER_URL=${AI_SERVER_URL:-$PROD_RAILWAY}"
  "--dart-define=SMS_SERVER_URL=${SMS_SERVER_URL:-$PROD_RAILWAY}"
  "--dart-define=GBP_SERVER_URL=${GBP_SERVER_URL:-$PROD_RAILWAY}"
  "--dart-define=STRIPE_SERVER_URL=${STRIPE_SERVER_URL:-$PROD_RAILWAY}"
  # ── Stripe ──────────────────────────────────────────────────────────────────
  "--dart-define=STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY:-}"
)

TARGET="${1:-web}"

case "$TARGET" in
  web)
    echo "🔨  Building Flutter web (release) → app.tradereppro.com"
    # --base-href / is required for Netlify deployment at the domain root.
    # Without it Flutter embeds a relative base href that breaks asset loading
    # when served from https://app.tradereppro.com/ (the CDN root).
    flutter build web --release --base-href / "${DEFINES[@]}"
    echo "✅  Build complete: build/web/"
    ;;
  apk)
    echo "🔨  Building Flutter APK (release)..."
    flutter build apk --release "${DEFINES[@]}"
    echo "✅  Build complete: build/app/outputs/flutter-apk/"
    ;;
  appbundle|aab)
    echo "🔨  Building Flutter App Bundle (release)..."
    flutter build appbundle --release "${DEFINES[@]}"
    echo "✅  Build complete: build/app/outputs/bundle/release/"
    ;;
  run)
    echo "🚀  Running Flutter (debug, web target)..."
    flutter run -d chrome "${DEFINES[@]}"
    ;;
  *)
    echo "Usage: $0 [web|apk|appbundle|run]"
    exit 1
    ;;
esac
