#!/usr/bin/env bash
# ==============================================================================
# colors.sh — Color definitions and terminal capability detection
# ==============================================================================

[[ -n "$_BASHCFG_COLORS_LOADED" ]] && return 0
_BASHCFG_COLORS_LOADED=1

# Detect color support
if [[ -t 1 ]] && [[ "${BASHCFG_COLORIZE:-1}" == "1" ]]; then
    export BASHCFG_COLOR_SUPPORT=1
else
    export BASHCFG_COLOR_SUPPORT=0
fi

# --- Named Colors (ANSI escape codes) ---
if [[ $BASHCFG_COLOR_SUPPORT -eq 1 ]]; then
    export CLR_RESET='\033[0m'
    export CLR_BOLD='\033[1m'
    export CLR_DIM='\033[2m'
    export CLR_UNDERLINE='\033[4m'

    # Foreground
    export CLR_BLACK='\033[30m'
    export CLR_RED='\033[31m'
    export CLR_GREEN='\033[32m'
    export CLR_YELLOW='\033[33m'
    export CLR_BLUE='\033[34m'
    export CLR_MAGENTA='\033[35m'
    export CLR_CYAN='\033[36m'
    export CLR_WHITE='\033[37m'
    export CLR_GRAY='\033[90m'

    # Bright foreground
    export CLR_BRED='\033[91m'
    export CLR_BGREEN='\033[92m'
    export CLR_BYELLOW='\033[93m'
    export CLR_BBLUE='\033[94m'
    export CLR_BMAGENTA='\033[95m'
    export CLR_BCYAN='\033[96m'
    export CLR_BWHITE='\033[97m'

    # Background
    export CLR_BG_RED='\033[41m'
    export CLR_BG_GREEN='\033[42m'
    export CLR_BG_YELLOW='\033[43m'
    export CLR_BG_BLUE='\033[44m'
else
    # No color support — empty strings
    export CLR_RESET='' CLR_BOLD='' CLR_DIM='' CLR_UNDERLINE=''
    export CLR_BLACK='' CLR_RED='' CLR_GREEN='' CLR_YELLOW=''
    export CLR_BLUE='' CLR_MAGENTA='' CLR_CYAN='' CLR_WHITE='' CLR_GRAY=''
    export CLR_BRED='' CLR_BGREEN='' CLR_BYELLOW='' CLR_BBLUE=''
    export CLR_BMAGENTA='' CLR_BCYAN='' CLR_BWHITE=''
    export CLR_BG_RED='' CLR_BG_GREEN='' CLR_BG_YELLOW='' CLR_BG_BLUE=''
fi

# --- Colorized Commands ---
if [[ $BASHCFG_COLOR_SUPPORT -eq 1 ]]; then
    # ls colors
    if [[ $BASHCFG_IS_MACOS -eq 1 ]]; then
        export CLICOLOR=1
        export LSCOLORS="GxFxCxDxBxegedabagaced"
    else
        export LS_COLORS='di=1;36:ln=1;35:so=1;32:pi=33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;43'
    fi

    # grep colors
    export GREP_COLORS='ms=01;31:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36'

    # less colors (for man pages)
    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # end mode
    export LESS_TERMCAP_se=$'\E[0m'        # end standout
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin standout (info box)
    export LESS_TERMCAP_ue=$'\E[0m'        # end underline
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline

    # GCC colors
    export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
fi

# Color test function
color_test() {
    echo -e "${CLR_RED}Red${CLR_RESET} ${CLR_GREEN}Green${CLR_RESET} ${CLR_YELLOW}Yellow${CLR_RESET} ${CLR_BLUE}Blue${CLR_RESET} ${CLR_MAGENTA}Magenta${CLR_RESET} ${CLR_CYAN}Cyan${CLR_RESET}"
    echo -e "${CLR_BOLD}Bold${CLR_RESET} ${CLR_DIM}Dim${CLR_RESET} ${CLR_UNDERLINE}Underline${CLR_RESET}"
}
