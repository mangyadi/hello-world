#!/usr/bin/env bash
# ==============================================================================
# default.sh — Default prompt theme
# ==============================================================================
# Dynamic prompt with: exit code, jobs, virtualenv, git branch/status,
# directory, and optional battery/hostname indicators.
# Uses PROMPT_COMMAND for dynamic updates without subshells where possible.
# ==============================================================================

[[ -n "$_BASHCFG_THEME_DEFAULT_LOADED" ]] && return 0
_BASHCFG_THEME_DEFAULT_LOADED=1

# --- Git Prompt Helpers ---
_prompt_git_branch() {
    local branch=""
    # Fast method: read HEAD directly (avoids subshell)
    if [[ -f .git/HEAD ]]; then
        read -r head < .git/HEAD
        case "$head" in
            ref:*) branch="${head#ref: refs/heads/}" ;;
            *)     branch="${head:0:7}" ;;  # Detached HEAD
        esac
    elif [[ $BASHCFG_HAS_GIT -eq 1 ]]; then
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || \
                 git rev-parse --short HEAD 2>/dev/null)
    fi
    echo "$branch"
}

_prompt_git_status() {
    [[ $BASHCFG_HAS_GIT -ne 1 ]] && return
    # Skip in non-git directories
    git rev-parse --is-inside-work-tree &>/dev/null || return

    local status_flags=""
    local git_status
    git_status=$(git status --porcelain=v1 2>/dev/null | head -20)

    [[ -n "$git_status" ]] && {
        echo "$git_status" | grep -q '^[MADRC]' && status_flags+="+"   # Staged
        echo "$git_status" | grep -q '^.[MD]'   && status_flags+="!"   # Modified
        echo "$git_status" | grep -q '^??'      && status_flags+="?"   # Untracked
    }

    echo "$status_flags"
}

# --- Prompt Construction ---
_prompt_command() {
    local exit_code=$?

    # Colors (using raw escapes for PS1 — must be wrapped in \[ \])
    local reset='\[\033[0m\]'
    local bold='\[\033[1m\]'
    local red='\[\033[31m\]'
    local green='\[\033[32m\]'
    local yellow='\[\033[33m\]'
    local blue='\[\033[34m\]'
    local magenta='\[\033[35m\]'
    local cyan='\[\033[36m\]'
    local gray='\[\033[90m\]'

    local ps1=""

    # --- Exit Code ---
    if [[ "${BASHCFG_PROMPT_SHOW_EXIT_CODE:-1}" == "1" && $exit_code -ne 0 ]]; then
        ps1+="${red}[${exit_code}]${reset} "
    fi

    # --- Background Jobs ---
    if [[ "${BASHCFG_PROMPT_SHOW_JOBS:-1}" == "1" ]]; then
        local job_count
        job_count=$(jobs -p 2>/dev/null | wc -l)
        if [[ $job_count -gt 0 ]]; then
            ps1+="${yellow}[${job_count}&]${reset} "
        fi
    fi

    # --- Time ---
    if [[ "${BASHCFG_PROMPT_SHOW_TIME:-0}" == "1" ]]; then
        ps1+="${gray}\t${reset} "
    fi

    # --- User@Host ---
    if [[ "${BASHCFG_PROMPT_SHOW_HOSTNAME:-0}" == "1" ]]; then
        if [[ $BASHCFG_IS_ROOT -eq 1 ]]; then
            ps1+="${red}${bold}\u@\h${reset} "
        else
            ps1+="${green}\u${reset}${gray}@${reset}${cyan}\h${reset} "
        fi
    elif [[ $BASHCFG_IS_ROOT -eq 1 ]]; then
        ps1+="${red}${bold}root${reset} "
    fi

    # --- Virtual Environment ---
    if [[ "${BASHCFG_PROMPT_SHOW_VENV:-1}" == "1" && -n "$VIRTUAL_ENV" ]]; then
        local venv_name
        venv_name=$(basename "$VIRTUAL_ENV")
        ps1+="${magenta}(${venv_name})${reset} "
    fi

    # --- Directory ---
    ps1+="${blue}${bold}\w${reset}"

    # --- Git Branch ---
    if [[ "${BASHCFG_PROMPT_SHOW_GIT:-1}" == "1" ]]; then
        local branch
        branch=$(_prompt_git_branch)
        if [[ -n "$branch" ]]; then
            local git_status
            git_status=$(_prompt_git_status)
            ps1+=" ${cyan}${branch}${reset}"
            if [[ -n "$git_status" ]]; then
                ps1+="${yellow}${git_status}${reset}"
            fi
        fi
    fi

    # --- Prompt Symbol ---
    if [[ $BASHCFG_IS_ROOT -eq 1 ]]; then
        ps1+="\n${red}#${reset} "
    else
        ps1+="\n${green}❯${reset} "
    fi

    PS1="$ps1"
}

# Disable default virtualenv prompt (we handle it ourselves)
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Set PROMPT_COMMAND
PROMPT_COMMAND="_prompt_command${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"
