#!/usr/bin/env bash
set -e

# ==============================================================================
# ✦ AuraDesk Pro — 1-Line Universal macOS Installer
# https://github.com/shubhransh-gupta/AuraDesk
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
WHITE="\033[97m"
DIM="\033[2m"
RESET="\033[0m"

echo ""
echo -e "${BOLD}${WHITE}✦ AURADESK PRO — 4K WALLPAPER & LOCK SCREEN ENGINE${RESET}"
echo -e "${DIM}  Zero-Drain Apple Silicon & Intel Native Architecture${RESET}"
echo ""

# 1. System check: macOS only
if [ "$(uname -s)" != "Darwin" ]; then
  echo -e "\033[31m✖ Error: AuraDesk Pro requires macOS.\033[0m"
  exit 1
fi

# 2. Check macOS version (14.0+)
OS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
if [ "$OS_MAJOR" -lt 14 ]; then
  echo -e "\033[33m▲ Notice: AuraDesk Pro is optimized for macOS 14+ (Sonoma, Sequoia, Tahoe).\033[0m"
fi

TARGET_APP="/Applications/AuraDesk.app"
ZIP_URL="https://github.com/shubhransh-gupta/AuraDesk/releases/latest/download/AuraDesk-macOS.zip"
TMP_DIR=$(mktemp -d /tmp/auradesk-install-XXXXXX)
TMP_ZIP="$TMP_DIR/AuraDesk-macOS.zip"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo -e "${CYAN}⚡ Fetching latest release from GitHub...${RESET}"
curl -fSL --progress-bar "$ZIP_URL" -o "$TMP_ZIP"

echo -e "${CYAN}📦 Unpacking AuraDesk.app...${RESET}"
unzip -q "$TMP_ZIP" -d "$TMP_DIR"

if [ ! -d "$TMP_DIR/AuraDesk.app" ]; then
  echo -e "\033[31m✖ Error: Failed to unpack AuraDesk.app archive.\033[0m"
  exit 1
fi

echo -e "${CYAN}🚀 Installing into /Applications...${RESET}"
# If AuraDesk is currently running, quit it gracefully
killall AuraDesk 2>/dev/null || true
sleep 0.5

# Check write access to /Applications
if [ -w "/Applications" ]; then
  rm -rf "$TARGET_APP"
  mv "$TMP_DIR/AuraDesk.app" "$TARGET_APP"
else
  echo -e "${DIM}  (Administrator privilege needed to write to /Applications)${RESET}"
  sudo rm -rf "$TARGET_APP"
  sudo mv "$TMP_DIR/AuraDesk.app" "$TARGET_APP"
fi

# Strip quarantine attribute to avoid Gatekeeper popups
xattr -cr "$TARGET_APP" 2>/dev/null || true

echo ""
echo -e "${GREEN}✔ AuraDesk Pro installed successfully into /Applications!${RESET}"
echo ""
echo -e "  ${WHITE}• Launch via Spotlight:${RESET} Press ${BOLD}Cmd+Space${RESET} and type ${BOLD}AuraDesk${RESET}"
echo -e "  ${WHITE}• Or from Terminal:${RESET}     ${DIM}open /Applications/AuraDesk.app${RESET}"
echo -e "  ${WHITE}• Homebrew Cask:${RESET}        ${DIM}brew install --cask shubhransh-gupta/tap/auradesk${RESET}"
echo ""

# Launch application
open "$TARGET_APP"
echo -e "${GREEN}✦ AuraDesk Pro is now running in your top Menu Bar!${RESET}"
echo ""
