#!/usr/bin/env bash
# ==============================================================================
# BashCraft — Uninstall Script
# ==============================================================================
set -euo pipefail

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

INSTALL_DIR="$HOME/.config/bash"
BASHRC="$HOME/.bashrc"

echo -e "${BOLD}${YELLOW}BashCraft Uninstaller${RESET}"
echo ""

read -rp "$(echo -e "${YELLOW}Remove BashCraft? This will delete ${INSTALL_DIR} [y/N]: ${RESET}")" reply
if [[ ! "$reply" =~ ^[Yy] ]]; then
    echo "Aborted."
    exit 0
fi

# Remove from .bashrc
if [[ -f "$BASHRC" ]]; then
    sed -i '/# >>> BashCraft >>>/,/# <<< BashCraft <<</d' "$BASHRC" 2>/dev/null
    echo -e "${GREEN}✔${RESET} Removed BashCraft from ~/.bashrc"
fi

# Remove config directory
if [[ -d "$INSTALL_DIR" ]]; then
    # Keep local overrides as backup
    if [[ -f "${INSTALL_DIR}/local/local.sh" ]]; then
        cp "${INSTALL_DIR}/local/local.sh" "$HOME/.bashcraft_local.sh.bak" 2>/dev/null
        echo -e "${CYAN}ℹ${RESET} Saved local.sh backup to ~/.bashcraft_local.sh.bak"
    fi

    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✔${RESET} Removed ${INSTALL_DIR}"
fi

echo ""
echo -e "${GREEN}BashCraft uninstalled.${RESET} Reload your shell: source ~/.bashrc"
