#!/usr/bin/env bash
# ==============================================================================
# exports.sh — Environment variable exports
# ==============================================================================

[[ -n "$_BASHCFG_EXPORTS_LOADED" ]] && return 0
_BASHCFG_EXPORTS_LOADED=1

# --- Editor ---
export EDITOR="${BASHCFG_EDITOR:-nano}"
export VISUAL="${EDITOR}"

# --- Pager ---
export PAGER="${BASHCFG_PAGER:-less}"
export LESS="-R -F -X -i -J --mouse"
export LESSHISTFILE="${BASHCFG_DIR}/cache/.lesshst"

# --- Locale ---
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-}"
export LC_CTYPE="${LC_CTYPE:-en_US.UTF-8}"

# --- XDG Directories ---
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# --- Shell Behavior ---
# Auto-cd: type directory name to cd into it
shopt -s autocd 2>/dev/null
# Correct minor spelling errors in cd
shopt -s cdspell 2>/dev/null
# Check window size after each command
shopt -s checkwinsize 2>/dev/null
# Include dotfiles in glob patterns
shopt -s dotglob 2>/dev/null
# Extended globbing (e.g., !(pattern), @(pat1|pat2))
shopt -s extglob 2>/dev/null
# ** matches directories recursively
shopt -s globstar 2>/dev/null
# Case-insensitive globbing
shopt -s nocaseglob 2>/dev/null
# Append to history instead of overwriting
shopt -s histappend 2>/dev/null

# --- Security ---
# Restrictive default umask
umask 022

# --- Termux Adjustments ---
if [[ $BASHCFG_IS_TERMUX -eq 1 ]]; then
    # Termux-specific LD paths
    export LD_LIBRARY_PATH="${PREFIX}/lib:${LD_LIBRARY_PATH:-}"
fi

# --- Make ---
# Use all available cores for make
export MAKEFLAGS="-j${BASHCFG_CPU_CORES}"
