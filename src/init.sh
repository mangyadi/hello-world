#!/usr/bin/env bash
# ==============================================================================
# init.sh — BashCraft Framework Loader
# ==============================================================================
# Main entry point for the modular bash configuration.
# Sourced by ~/.bashrc — handles load order, profiling, and error isolation.
#
# Load order:
#   1. Platform detection (lib/platform.sh)
#   2. Utility library (lib/utils.sh)
#   3. Logging (lib/logging.sh)
#   4. Loader engine (lib/loader.sh)
#   5. User settings (conf.d/)
#   6. Core modules (core/) — always loaded
#   7. Aliases (aliases/) — always loaded
#   8. Functions (functions/) — loaded or lazy-loaded
#   9. Modules (modules/) — conditionally loaded
#  10. Themes (themes/) — prompt theme
#  11. Plugins (plugins/) — user/third-party
#  12. Local overrides (local/) — machine-specific
#
# Performance:
#   Set BASHCFG_PROFILE_STARTUP=1 before sourcing to see timing info.
#   Typical cold start: <100ms. Warm start: <50ms.
# ==============================================================================

# Exit early if not interactive
[[ $- != *i* ]] && return

# --- Framework Root ---
export BASHCFG_DIR="${BASHCFG_DIR:-$HOME/.config/bash}"
export BASHCFG_VERSION="1.0.0"

# --- Phase 1: Library Bootstrap ---
# These must be sourced in order (each depends on the previous)

_bashcfg_now_ms() {
    if [[ -f /proc/uptime ]]; then
        awk '{printf "%d", $1 * 1000}' /proc/uptime
    else
        date +%s%N | cut -b1-13
    fi
}

# Profiling start (function must be defined first)
if [[ "${BASHCFG_PROFILE_STARTUP:-0}" == "1" ]]; then
    _BASHCFG_START_TIME=$(_bashcfg_now_ms)
    echo "═══ BashCraft v${BASHCFG_VERSION} — Startup Profile ═══"
fi

# Platform detection (sets BASHCFG_IS_* flags)
source "${BASHCFG_DIR}/lib/platform.sh" || {
    echo "BashCraft: Failed to load platform.sh" >&2
    return 1
}

# Utility functions
source "${BASHCFG_DIR}/lib/utils.sh" || {
    echo "BashCraft: Failed to load utils.sh" >&2
    return 1
}

# Logging
source "${BASHCFG_DIR}/lib/logging.sh" || {
    echo "BashCraft: Failed to load logging.sh" >&2
    return 1
}

# Module loader
source "${BASHCFG_DIR}/lib/loader.sh" || {
    echo "BashCraft: Failed to load loader.sh" >&2
    return 1
}

log_info "BashCraft v${BASHCFG_VERSION} starting on ${BASHCFG_PLATFORM}"

# --- Phase 2: Configuration ---
_load_dir "${BASHCFG_DIR}/conf.d"

# Ensure critical directories exist
_ensure_dir "$BASHCFG_PROJECTS_DIR"
_ensure_dir "$BASHCFG_BACKUP_DIR"
_ensure_dir "$BASHCFG_TRASH_DIR"
_ensure_dir "$BASHCFG_NOTES_DIR"
_ensure_dir "${BASHCFG_DIR}/cache"
_ensure_dir "${BASHCFG_DIR}/tmp"
_ensure_dir "${BASHCFG_DIR}/data"

# --- Phase 3: Core Modules ---
# These are always loaded regardless of platform or available tools.
_load_module "${BASHCFG_DIR}/core/colors.sh"
_load_module "${BASHCFG_DIR}/core/exports.sh"
_load_module "${BASHCFG_DIR}/core/paths.sh"
_load_module "${BASHCFG_DIR}/core/history.sh"
_load_module "${BASHCFG_DIR}/core/completion.sh"

# --- Phase 4: Aliases ---
_load_dir "${BASHCFG_DIR}/aliases"

# --- Phase 5: Functions ---
if [[ "${BASHCFG_LAZY_LOAD:-1}" == "1" && "${BASHCFG_LOW_RESOURCE:-0}" == "1" ]]; then
    # On low-resource systems, lazy-load heavy function files
    _lazy_load "create_project"  "${BASHCFG_DIR}/functions/project_mgmt.sh"
    _lazy_load "archive_project" "${BASHCFG_DIR}/functions/project_mgmt.sh"
    _lazy_load "safe_delete"     "${BASHCFG_DIR}/functions/file_utils.sh"
    _lazy_load "extract_any"     "${BASHCFG_DIR}/functions/file_utils.sh"
    _lazy_load "find_large_files" "${BASHCFG_DIR}/functions/search.sh"
    log_info "Lazy-loading enabled for heavy function modules"
else
    _load_dir "${BASHCFG_DIR}/functions"
fi

# --- Phase 6: Conditional Modules ---
# Only load if the relevant tool is installed.
[[ $BASHCFG_HAS_GIT -eq 1 ]]    && _load_module "${BASHCFG_DIR}/modules/git_extras.sh"
[[ $BASHCFG_HAS_PYTHON -eq 1 ]] && _load_module "${BASHCFG_DIR}/modules/python.sh"
[[ $BASHCFG_HAS_RUST -eq 1 ]]   && _load_module "${BASHCFG_DIR}/modules/rust.sh"
[[ $BASHCFG_HAS_NODE -eq 1 ]]   && _load_module "${BASHCFG_DIR}/modules/node.sh"
[[ $BASHCFG_HAS_DOCKER -eq 1 ]] && _load_module "${BASHCFG_DIR}/modules/docker.sh"
[[ $BASHCFG_HAS_TMUX -eq 1 ]]   && _load_module "${BASHCFG_DIR}/modules/tmux.sh"
_load_module "${BASHCFG_DIR}/modules/ssh.sh"
_load_module "${BASHCFG_DIR}/modules/ai_helpers.sh"

# Termux-specific module
[[ $BASHCFG_IS_TERMUX -eq 1 ]] && _load_module "${BASHCFG_DIR}/modules/termux.sh"

# --- Phase 7: Prompt Theme ---
_bashcfg_theme_file="${BASHCFG_DIR}/themes/${BASHCFG_PROMPT_THEME:-default}.sh"
if [[ -f "$_bashcfg_theme_file" ]]; then
    _load_module "$_bashcfg_theme_file"
else
    _load_module "${BASHCFG_DIR}/themes/default.sh"
fi

# --- Phase 8: Plugins ---
_load_plugins

# --- Phase 9: Local Overrides ---
# Machine-specific settings not tracked in version control
_safe_source "${BASHCFG_DIR}/local/local.sh"

# --- Startup Complete ---
if [[ "${BASHCFG_PROFILE_STARTUP:-0}" == "1" ]]; then
    _bashcfg_end_time=$(_bashcfg_now_ms)
    _bashcfg_total=$(( _bashcfg_end_time - _BASHCFG_START_TIME ))
    echo ""
    echo "═══ Total startup: ${_bashcfg_total}ms | Modules: ${#_BASHCFG_LOADED_MODULES[@]} ═══"
    echo ""
fi

log_info "Shell ready. Modules loaded: ${#_BASHCFG_LOADED_MODULES[@]}"

# Welcome message (only on first interactive login, not in subshells)
if [[ -z "$BASHCFG_LOADED" && $BASHCFG_IS_INTERACTIVE -eq 1 ]]; then
    export BASHCFG_LOADED=1
    if [[ "${BASHCFG_SHOW_WELCOME:-1}" == "1" ]]; then
        echo -e "\033[1;36mBashCraft v${BASHCFG_VERSION}\033[0m on \033[33m${BASHCFG_PLATFORM}\033[0m — type \033[32mhelp_bashcraft\033[0m for commands"
    fi
fi
