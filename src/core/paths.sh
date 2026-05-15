#!/usr/bin/env bash
# ==============================================================================
# paths.sh — PATH construction
# ==============================================================================
# Adds directories to PATH only if they exist, avoiding duplicates.
# ==============================================================================

[[ -n "$_BASHCFG_PATHS_LOADED" ]] && return 0
_BASHCFG_PATHS_LOADED=1

# Add to PATH (prepend) if directory exists and isn't already in PATH
_path_prepend() {
    local dir="$1"
    if [[ -d "$dir" && ":${PATH}:" != *":${dir}:"* ]]; then
        export PATH="${dir}:${PATH}"
    fi
}

# Add to PATH (append) if directory exists and isn't already in PATH
_path_append() {
    local dir="$1"
    if [[ -d "$dir" && ":${PATH}:" != *":${dir}:"* ]]; then
        export PATH="${PATH}:${dir}"
    fi
}

# --- User Paths (highest priority) ---
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"

# --- Language-Specific Paths ---
# Rust
_path_prepend "$HOME/.cargo/bin"

# Go
if [[ -d "$HOME/go/bin" ]]; then
    export GOPATH="${GOPATH:-$HOME/go}"
    _path_prepend "$GOPATH/bin"
fi

# Node (nvm/fnm/volta)
_path_prepend "$HOME/.npm-global/bin"
_path_prepend "$HOME/.volta/bin"

# Python (pip --user)
_path_prepend "$HOME/.local/bin"

# Deno
_path_prepend "$HOME/.deno/bin"

# Bun
_path_prepend "$HOME/.bun/bin"

# --- Termux-Specific ---
if [[ $BASHCFG_IS_TERMUX -eq 1 ]]; then
    _path_prepend "${PREFIX}/bin"
    _path_prepend "${PREFIX}/bin/applets"
fi

# --- System Paths (lower priority, append) ---
_path_append "/usr/local/bin"
_path_append "/usr/local/sbin"
