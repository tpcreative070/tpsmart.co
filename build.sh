#!/usr/bin/env bash
# =============================================================================
#  build.sh — Deploy TPSmart to Firebase Hosting
#  Project: tpsmart-ae96d
#  Custom domain: tpsmart.co
#  Usage:   ./build.sh            → deploy to live
#           ./build.sh --preview  → deploy to a temporary preview URL
# =============================================================================

set -euo pipefail

# ── Make this script executable on first run ──────────────────────────────────
chmod +x "$0"

# ── Config ────────────────────────────────────────────────────────────────────
PROJECT_ID="tpsmart-ae96d"
PUBLIC_DIR="public"
PREVIEW_CHANNEL="preview-$(date +%Y%m%d-%H%M%S)"

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}${BOLD}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $*" >&2; exit 1; }

# ── Parse arguments ───────────────────────────────────────────────────────────
PREVIEW_MODE=false
for arg in "$@"; do
  [[ "$arg" == "--preview" ]] && PREVIEW_MODE=true
done

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║         TPSmart — Firebase Deploy        ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── 1. Check Firebase CLI ─────────────────────────────────────────────────────
info "Checking Firebase CLI..."
if ! command -v firebase &>/dev/null; then
  warn "Firebase CLI not found. Installing globally via npm..."
  npm install -g firebase-tools || error "npm install failed. Please install Node.js first."
fi
FIREBASE_VER=$(firebase --version 2>/dev/null || echo "unknown")
success "Firebase CLI ready (v${FIREBASE_VER})"

# ── 2. Login check ────────────────────────────────────────────────────────────
info "Checking Firebase login status..."
if ! firebase projects:list &>/dev/null; then
  warn "Not logged in. Opening browser for authentication..."
  firebase login || error "Firebase login failed."
fi
success "Authenticated with Firebase"

# ── 3. Verify public directory and index.html exist ───────────────────────────
info "Verifying project structure..."
[[ -d "$PUBLIC_DIR" ]]            || error "'${PUBLIC_DIR}/' folder not found. Are you in the project root?"
[[ -f "$PUBLIC_DIR/index.html" ]] || error "'${PUBLIC_DIR}/index.html' not found."
[[ -f "firebase.json" ]]          || error "firebase.json not found."
success "Structure OK — public/index.html and firebase.json found"

# ── 4. Deploy ─────────────────────────────────────────────────────────────────
if [[ "$PREVIEW_MODE" == true ]]; then
  info "Deploying to preview channel: ${PREVIEW_CHANNEL}..."
  firebase hosting:channel:deploy "${PREVIEW_CHANNEL}" \
    --project "${PROJECT_ID}" \
    --expires 7d
  echo ""
  success "Preview deployed! Expires in 7 days."
else
  info "Deploying to LIVE (${PROJECT_ID})..."
  firebase deploy --only hosting --project "${PROJECT_ID}"
  echo ""
  success "Live deployment complete!"
  echo -e "  ${BOLD}URLs:${RESET}"
  echo -e "       https://${PROJECT_ID}.web.app"
  echo -e "       https://${PROJECT_ID}.firebaseapp.com"
  echo -e "       https://tpsmart.co  (custom domain)"
fi

echo ""
echo -e "${GREEN}${BOLD}Done ✓${RESET}"
