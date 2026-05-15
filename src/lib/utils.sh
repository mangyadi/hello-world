#!/usr/bin/env bash
# ==============================================================================
# utils.sh — Shared utility functions used across all modules
# ==============================================================================

[[ -n "$_BASHCFG_UTILS_LOADED" ]] && return 0
_BASHCFG_UTILS_LOADED=1

# --- Output Helpers ---

# Print colored message: _print_color <color_code> <message>
_print_color() {
    local color="$1"; shift
    echo -e "\033[${color}m$*\033[0m"
}

_print_success() { _print_color "32" "✔ $*"; }
_print_error()   { _print_color "31" "✖ $*" >&2; }
_print_warn()    { _print_color "33" "⚠ $*"; }
_print_info()    { _print_color "36" "ℹ $*"; }
_print_header()  { _print_color "1;34" "═══ $* ═══"; }

# --- Validation ---

# Check if a command exists
_cmd_exists() { command -v "$1" &>/dev/null; }

# Check if a variable is set and non-empty
_is_set() { [[ -n "${!1:-}" ]]; }

# Check if running interactively
_is_interactive() { [[ $BASHCFG_IS_INTERACTIVE -eq 1 ]]; }

# --- Confirmation ---

# Ask yes/no: _confirm "message" (returns 0 for yes)
_confirm() {
    local msg="${1:-Are you sure?}"
    local reply
    read -rp "$(echo -e "\033[33m$msg [y/N]: \033[0m")" reply
    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# --- String Helpers ---

# Trim whitespace
_trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# Convert to lowercase
_lowercase() { echo "${1,,}"; }

# Convert to uppercase
_uppercase() { echo "${1^^}"; }

# --- Path Helpers ---

# Ensure directory exists
_ensure_dir() {
    [[ -d "$1" ]] || mkdir -p "$1" 2>/dev/null
}

# Get absolute path (pure bash, no realpath dependency)
_abspath() {
    if [[ -d "$1" ]]; then
        (cd "$1" && pwd)
    elif [[ -f "$1" ]]; then
        local dir
        dir=$(cd "$(dirname "$1")" && pwd)
        echo "$dir/$(basename "$1")"
    else
        echo "$1"
    fi
}

# --- File Helpers ---

# Safe source: source file only if it exists and is readable
_safe_source() {
    [[ -f "$1" && -r "$1" ]] && source "$1"
}

# Get file size in human-readable format
_file_size() {
    if [[ -f "$1" ]]; then
        ls -lh "$1" | awk '{print $5}'
    fi
}

# --- Timing ---

# Get current time in milliseconds (for profiling)
_now_ms() {
    if [[ -f /proc/uptime ]]; then
        awk '{printf "%d", $1 * 1000}' /proc/uptime
    else
        date +%s%N | cut -b1-13
    fi
}

# --- Array Helpers ---

# Check if value is in array: _in_array "value" "${array[@]}"
_in_array() {
    local needle="$1"; shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# --- Platform-Aware Helpers ---

# Open file/URL with system handler
_open() {
    if [[ $BASHCFG_IS_TERMUX -eq 1 ]]; then
        termux-open "$@" 2>/dev/null || xdg-open "$@" 2>/dev/null
    elif [[ $BASHCFG_IS_MACOS -eq 1 ]]; then
        open "$@"
    elif [[ $BASHCFG_IS_WSL -eq 1 ]]; then
        wslview "$@" 2>/dev/null || explorer.exe "$@" 2>/dev/null
    else
        xdg-open "$@" 2>/dev/null
    fi
}

# Copy to clipboard
_clip() {
    if [[ $BASHCFG_IS_TERMUX -eq 1 ]]; then
        termux-clipboard-set
    elif [[ $BASHCFG_IS_MACOS -eq 1 ]]; then
        pbcopy
    elif _cmd_exists xclip; then
        xclip -selection clipboard
    elif _cmd_exists xsel; then
        xsel --clipboard --input
    else
        _print_warn "No clipboard tool found"
        return 1
    fi
}
