#!/usr/bin/env bash
# ==============================================================================
# general.sh — General-purpose aliases
# ==============================================================================

# --- Listing ---
if [[ $BASHCFG_IS_MACOS -eq 1 ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=auto --group-directories-first'
fi
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -alFht'          # Sort by time
alias lS='ls -alFhS'          # Sort by size
alias l1='ls -1'              # One per line
alias lsd='ls -d */'          # Directories only
alias lsf='ls -p | grep -v /' # Files only

# --- File Operations ---
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias ln='ln -iv'

# --- Grep ---
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias rg='rg --color=auto 2>/dev/null || grep -rn --color=auto'

# --- Disk Usage ---
alias df='df -h'
alias du='du -h'
alias dud='du -d 1 -h | sort -hr'  # Directory sizes, sorted
alias duf='du -sh *'               # File sizes in current dir

# --- Process ---
alias psg='ps aux | grep -v grep | grep -i'
alias psmem='ps aux --sort=-%mem | head -20'
alias pscpu='ps aux --sort=-%cpu | head -20'

# --- Network ---
alias ports='ss -tulanp 2>/dev/null || netstat -tulanp 2>/dev/null'
alias myip='curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com'
alias localip='hostname -I 2>/dev/null | awk "{print \$1}"'
alias ping3='ping -c 3'
alias wget='wget -c'  # Resume by default

# --- System ---
alias reload='source ~/.bashrc && echo "Shell reloaded"'
alias path='echo -e "${PATH//:/\\n}"'
alias now='date "+%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias timer='echo "Timer started. Ctrl-D to stop." && date && time cat && date'

# --- Text ---
alias less='less -R'
alias more='less'
alias head='head -n 20'
alias tail='tail -n 20'
alias tailf='tail -f'
alias count='wc -l'

# --- Misc ---
alias c='clear'
alias h='history'
alias j='jobs -l'
alias which='type -a'
alias map='xargs -n1'
please() { sudo "$(fc -ln -1)"; }
alias ':q'='exit'
alias 'q'='exit'

# --- Chmod shortcuts ---
alias cx='chmod +x'
alias c644='chmod 644'
alias c755='chmod 755'
alias c700='chmod 700'

# --- Quick Editing ---
alias bashrc='${EDITOR} ~/.bashrc'
alias bashconf='cd ${BASHCFG_DIR} && ${EDITOR} .'
