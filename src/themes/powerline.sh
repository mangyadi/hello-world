#!/usr/bin/env bash
# ==============================================================================
# powerline.sh — Rich powerline-style prompt
# ==============================================================================
# Feature-rich prompt with segments. Requires Unicode support.
# ==============================================================================

[[ -n "$_BASHCFG_THEME_POWERLINE_LOADED" ]] && return 0
_BASHCFG_THEME_POWERLINE_LOADED=1

export VIRTUAL_ENV_DISABLE_PROMPT=1

_prompt_command_powerline() {
    local exit_code=$?

    local reset='\[\033[0m\]'
    local bold='\[\033[1m\]'

    # Segment colors
    local seg_user_bg='\[\033[44m\]'    # Blue bg
    local seg_user_fg='\[\033[97m\]'    # White fg
    local seg_dir_bg='\[\033[46m\]'     # Cyan bg
    local seg_dir_fg='\[\033[30m\]'     # Black fg
    local seg_git_bg='\[\033[43m\]'     # Yellow bg
    local seg_git_fg='\[\033[30m\]'     # Black fg
    local seg_err_bg='\[\033[41m\]'     # Red bg
    local seg_err_fg='\[\033[97m\]'     # White fg

    local ps1=""

    # Error segment
    if [[ $exit_code -ne 0 ]]; then
        ps1+="${seg_err_bg}${seg_err_fg} ✖ ${exit_code} ${reset}"
    fi

    # Venv segment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        ps1+="\[\033[45m\]\[\033[97m\] 🐍 $(basename "$VIRTUAL_ENV") ${reset}"
    fi

    # User segment (only on SSH or root)
    if [[ $BASHCFG_IS_SSH -eq 1 || $BASHCFG_IS_ROOT -eq 1 ]]; then
        ps1+="${seg_user_bg}${seg_user_fg} \u@\h ${reset}"
    fi

    # Directory segment
    ps1+="${seg_dir_bg}${seg_dir_fg}${bold} \w ${reset}"

    # Git segment
    if [[ "${BASHCFG_PROMPT_SHOW_GIT:-1}" == "1" ]]; then
        local branch
        if [[ -f .git/HEAD ]]; then
            read -r head < .git/HEAD
            case "$head" in
                ref:*) branch="${head#ref: refs/heads/}" ;;
                *)     branch="${head:0:7}" ;;
            esac
        elif [[ $BASHCFG_HAS_GIT -eq 1 ]]; then
            branch=$(git symbolic-ref --short HEAD 2>/dev/null || \
                     git rev-parse --short HEAD 2>/dev/null)
        fi
        if [[ -n "$branch" ]]; then
            ps1+="${seg_git_bg}${seg_git_fg} ⎇ ${branch} ${reset}"
        fi
    fi

    ps1+="\n❯ "
    PS1="$ps1"
}

PROMPT_COMMAND="_prompt_command_powerline${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"
