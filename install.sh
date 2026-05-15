#!/usr/bin/env bash
# ==============================================================================
# BashCraft — Install Script
# ==============================================================================
# Installs the modular .bashrc framework.
# Safe: backs up existing config before making changes.
#
# Usage:
#   bash install.sh          # Interactive install
#   bash install.sh --yes    # Auto-accept defaults
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}ℹ${RESET} $*"; }
success() { echo -e "${GREEN}✔${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
error()   { echo -e "${RED}✖${RESET} $*" >&2; }

# --- Configuration ---
INSTALL_DIR="$HOME/.config/bash"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/src"
AUTO_YES="${1:-}"
BACKUP_DIR="$HOME/.config/bash_backup_$(date +%Y%m%d_%H%M%S)"

confirm() {
    [[ "$AUTO_YES" == "--yes" ]] && return 0
    local reply
    read -rp "$(echo -e "${YELLOW}$1 [y/N]: ${RESET}")" reply
    [[ "$reply" =~ ^[Yy] ]]
}

# --- Header ---
echo ""
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════${RESET}"
echo -e "${BOLD}${BLUE}  BashCraft — Modular Shell Framework     ${RESET}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════${RESET}"
echo ""

# --- Pre-flight Checks ---
if [[ ! -d "$SRC_DIR" ]]; then
    error "Source directory not found: $SRC_DIR"
    error "Run this script from the bashrc-framework directory."
    exit 1
fi

info "Install directory: ${INSTALL_DIR}"
info "Source: ${SRC_DIR}"
echo ""

# --- Backup Existing Config ---
if [[ -d "$INSTALL_DIR" ]]; then
    warn "Existing config found at ${INSTALL_DIR}"
    if confirm "Back up and replace?"; then
        cp -r "$INSTALL_DIR" "$BACKUP_DIR"
        success "Backed up to: ${BACKUP_DIR}"
    else
        error "Aborted."
        exit 0
    fi
fi

# --- Install Framework ---
info "Installing BashCraft..."

# Create directory structure
mkdir -p "$INSTALL_DIR"

# Copy source files
cp -r "$SRC_DIR"/* "$INSTALL_DIR/"

# Create runtime directories
mkdir -p "$INSTALL_DIR"/{cache,logs,tmp,data/sessions,data/prompts,data/templates}

# Create local.sh if it doesn't exist
if [[ ! -f "$INSTALL_DIR/local/local.sh" ]]; then
    cp "$INSTALL_DIR/local/local.sh.example" "$INSTALL_DIR/local/local.sh" 2>/dev/null || true
fi

success "Framework installed to: ${INSTALL_DIR}"

# --- Set Up .bashrc ---
BASHRC="$HOME/.bashrc"
BASHRC_MARKER="# >>> BashCraft >>>"
BASHRC_END_MARKER="# <<< BashCraft <<<"

if [[ -f "$BASHRC" ]] && grep -q "$BASHRC_MARKER" "$BASHRC" 2>/dev/null; then
    info ".bashrc already configured for BashCraft"
else
    if [[ -f "$BASHRC" ]]; then
        cp "$BASHRC" "${BASHRC}.bak.$(date +%Y%m%d_%H%M%S)"
        success "Backed up existing .bashrc"
    fi

    if confirm "Add BashCraft loader to ~/.bashrc?"; then
        cat >> "$BASHRC" << 'EOF'

# >>> BashCraft >>>
# Modular shell framework — https://github.com/bashcraft
export BASHCFG_DIR="${BASHCFG_DIR:-$HOME/.config/bash}"
[[ -f "${BASHCFG_DIR}/init.sh" ]] && source "${BASHCFG_DIR}/init.sh"
# <<< BashCraft <<<
EOF
        success "Added BashCraft loader to ~/.bashrc"
    fi
fi

# --- Platform-Specific Setup ---
echo ""
info "Detected platform: $(uname -s)"

# Detect Termux
if [[ -d "/data/data/com.termux" ]]; then
    info "Termux detected — Android optimizations enabled"
    info "Tip: Run 'termux-setup-storage' for storage access"
    info "Tip: Install extras: pkg install git python nodejs-lts fzf jq"
fi

# --- Optional Dependencies ---
echo ""
info "Optional tools for full functionality:"
echo "  • fzf      — fuzzy finder (interactive menus, search)"
echo "  • jq       — JSON processing"
echo "  • ripgrep  — fast code search (rg)"
echo "  • tree     — directory visualization"
echo "  • tmux     — terminal multiplexer"
echo ""

# Check what's available
for tool in fzf jq rg tree tmux; do
    if command -v "$tool" &>/dev/null; then
        success "$tool — installed"
    else
        warn "$tool — not installed"
    fi
done

# --- Done ---
echo ""
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════${RESET}"
echo -e "${BOLD}${GREEN}  Installation complete!                    ${RESET}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════${RESET}"
echo ""
echo "  Reload your shell:"
echo "    source ~/.bashrc"
echo ""
echo "  Or start a new terminal session."
echo ""
echo "  Quick start:"
echo "    help_bashcraft     — Show all commands"
echo "    _startup_report    — Show startup timing"
echo "    palette            — Command palette (requires fzf)"
echo ""
echo "  Configuration:"
echo "    ${INSTALL_DIR}/conf.d/settings.sh  — Main settings"
echo "    ${INSTALL_DIR}/local/local.sh      — Your overrides"
echo ""
echo "  Profile startup:"
echo "    BASHCFG_PROFILE_STARTUP=1 bash -i"
echo ""
