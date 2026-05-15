#!/usr/bin/env bash
# ==============================================================================
# minimal.sh — Minimal prompt theme for low-resource environments
# ==============================================================================
# Ultra-lightweight: no subshells, no git status, minimal processing.
# Ideal for Termux on low-RAM devices or when performance is critical.
# ==============================================================================

[[ -n "$_BASHCFG_THEME_MINIMAL_LOADED" ]] && return 0
_BASHCFG_THEME_MINIMAL_LOADED=1

export VIRTUAL_ENV_DISABLE_PROMPT=1

_prompt_command_minimal() {
    local exit_code=$?

    local ps1=""

    # Exit code indicator (just color the prompt symbol)
    if [[ $exit_code -ne 0 ]]; then
        ps1='\[\033[31m\]\w ✖\[\033[0m\] '
    else
        ps1='\[\033[36m\]\w\[\033[0m\] \[\033[32m\]❯\[\033[0m\] '
    fi

    # Show venv if active
    if [[ -n "$VIRTUAL_ENV" ]]; then
        ps1="\[\033[35m\]($(basename "$VIRTUAL_ENV"))\[\033[0m\] ${ps1}"
    fi

    PS1="$ps1"
}

PROMPT_COMMAND="_prompt_command_minimal${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"
