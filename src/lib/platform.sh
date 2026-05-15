#!/usr/bin/env bash
# ==============================================================================
# platform.sh — Platform detection and capability flags
# ==============================================================================
# Detects: Termux, proot-distro Ubuntu, native Linux, WSL, macOS
# Sets global flags used by all modules for conditional behavior.
# This file is sourced early and MUST be fast (no subshells where avoidable).
# ==============================================================================

# Guard against double-sourcing
[[ -n "$_BASHCFG_PLATFORM_LOADED" ]] && return 0
_BASHCFG_PLATFORM_LOADED=1

# --- Platform Flags ---
export BASHCFG_IS_TERMUX=0
export BASHCFG_IS_PROOT=0
export BASHCFG_IS_WSL=0
export BASHCFG_IS_MACOS=0
export BASHCFG_IS_LINUX=0
export BASHCFG_IS_ANDROID=0
export BASHCFG_IS_SSH=0
export BASHCFG_IS_ROOT=0
export BASHCFG_IS_INTERACTIVE=0
export BASHCFG_PLATFORM="unknown"

# Detect interactive shell
[[ $- == *i* ]] && BASHCFG_IS_INTERACTIVE=1

# Detect root
[[ $EUID -eq 0 ]] && BASHCFG_IS_ROOT=1

# Detect SSH session
[[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]] && BASHCFG_IS_SSH=1

# --- Platform Detection ---
if [[ -d "/data/data/com.termux" ]]; then
    BASHCFG_IS_TERMUX=1
    BASHCFG_IS_ANDROID=1
    BASHCFG_PLATFORM="termux"
    # Detect if inside proot-distro
    if [[ -f /etc/os-release ]] && grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
        if [[ "$(uname -r 2>/dev/null)" == *-android* ]] || [[ -n "$PROOT_TMP_DIR" ]]; then
            BASHCFG_IS_PROOT=1
            BASHCFG_PLATFORM="proot-ubuntu"
        fi
    fi
elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then
    BASHCFG_IS_MACOS=1
    BASHCFG_PLATFORM="macos"
elif [[ -f /proc/version ]] && grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
    BASHCFG_IS_WSL=1
    BASHCFG_IS_LINUX=1
    BASHCFG_PLATFORM="wsl"
elif [[ "$(uname -s 2>/dev/null)" == "Linux" ]]; then
    BASHCFG_IS_LINUX=1
    BASHCFG_PLATFORM="linux"
fi

# --- Capability Detection ---
# These avoid repeated `command -v` calls throughout the framework
export BASHCFG_HAS_GIT=0
export BASHCFG_HAS_PYTHON=0
export BASHCFG_HAS_RUST=0
export BASHCFG_HAS_NODE=0
export BASHCFG_HAS_DOCKER=0
export BASHCFG_HAS_TMUX=0
export BASHCFG_HAS_FZF=0
export BASHCFG_HAS_JQ=0
export BASHCFG_HAS_CURL=0

command -v git    &>/dev/null && BASHCFG_HAS_GIT=1
command -v python3 &>/dev/null && BASHCFG_HAS_PYTHON=1
command -v rustc  &>/dev/null && BASHCFG_HAS_RUST=1
command -v node   &>/dev/null && BASHCFG_HAS_NODE=1
command -v docker &>/dev/null && BASHCFG_HAS_DOCKER=1
command -v tmux   &>/dev/null && BASHCFG_HAS_TMUX=1
command -v fzf    &>/dev/null && BASHCFG_HAS_FZF=1
command -v jq     &>/dev/null && BASHCFG_HAS_JQ=1
command -v curl   &>/dev/null && BASHCFG_HAS_CURL=1

# --- Resource Constraints ---
# Memory in MB (fallback: 2048)
if [[ -f /proc/meminfo ]]; then
    BASHCFG_TOTAL_RAM=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
else
    BASHCFG_TOTAL_RAM=2048
fi
export BASHCFG_TOTAL_RAM

# Low-resource mode: <2GB RAM or explicitly set
if [[ ${BASHCFG_TOTAL_RAM:-2048} -lt 2048 ]] || [[ "$BASHCFG_LOW_RESOURCE" == "1" ]]; then
    export BASHCFG_LOW_RESOURCE=1
else
    export BASHCFG_LOW_RESOURCE=0
fi

# Number of CPU cores
export BASHCFG_CPU_CORES
BASHCFG_CPU_CORES=$(nproc 2>/dev/null || echo 2)
