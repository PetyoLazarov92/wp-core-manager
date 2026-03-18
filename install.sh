#!/usr/bin/env bash
# ============================================================
# wpcore installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/PetyoLazarov92/wp-core-manager/main/install.sh | sudo bash
# ============================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}▸${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
die()     { echo -e "${RED}✗ Error:${RESET} $*" >&2; exit 1; }

# ── Must run as root ──────────────────────────────────────────
[[ $EUID -eq 0 ]] || die "Please run with sudo:\n  curl -fsSL https://raw.githubusercontent.com/PetyoLazarov92/wp-core-manager/main/install.sh | sudo bash"

INSTALL_DIR="/usr/local/bin"
BINARY="$INSTALL_DIR/wpcore"
RAW_URL="https://raw.githubusercontent.com/PetyoLazarov92/wp-core-manager/main/wpcore"

echo -e "\n${BOLD}wpcore installer${RESET}\n"

# ── Check for wget or curl ────────────────────────────────────
if command -v wget &>/dev/null; then
    DOWNLOADER="wget"
elif command -v curl &>/dev/null; then
    DOWNLOADER="curl"
else
    die "Neither wget nor curl is available. Install one and re-run."
fi

# ── Download wpcore ───────────────────────────────────────────
info "Downloading wpcore from GitHub..."
if [[ "$DOWNLOADER" == "wget" ]]; then
    wget -q -O "$BINARY" "$RAW_URL"
else
    curl -fsSL -o "$BINARY" "$RAW_URL"
fi

# ── Make executable ───────────────────────────────────────────
chmod +x "$BINARY"
success "Installed: $BINARY"

# ── Verify ────────────────────────────────────────────────────
if ! command -v wpcore &>/dev/null; then
    warn "$INSTALL_DIR is not in PATH. Add it:"
    echo "    export PATH=\"\$PATH:$INSTALL_DIR\""
fi

# ── Offer to initialize ───────────────────────────────────────
echo ""
echo -e "${BOLD}wpcore has been installed.${RESET}"
echo ""
echo "  Next step — run initialization to create the config file"
echo "  (/etc/wpcore.conf) and install Bash tab completion:"
echo ""
echo -e "    ${CYAN}sudo wpcore init${RESET}"
echo ""

# If running in a non-interactive pipe (| sudo bash), skip prompt
if [[ -t 0 ]]; then
    read -rp "Run 'wpcore init' now? [Y/n] " answer
    answer="${answer:-Y}"
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo ""
        wpcore init
    else
        info "Skipped. Run 'sudo wpcore init' when ready."
    fi
else
    info "Run 'sudo wpcore init' to finish setup."
fi

echo ""
success "Done! Run 'wpcore help' to get started."
echo ""
