#!/usr/bin/env bash
# ==============================================================================
# tmux.sh — tmux session management helpers
# ==============================================================================

[[ -n "$_BASHCFG_TMUX_LOADED" ]] && return 0
_BASHCFG_TMUX_LOADED=1

# --- Session Management ---
# Create or attach to named session
ta() {
    local name="${1:-main}"
    if tmux has-session -t "$name" 2>/dev/null; then
        tmux attach-session -t "$name"
    else
        tmux new-session -s "$name"
    fi
}

# List sessions
alias tls='tmux list-sessions 2>/dev/null || echo "No tmux sessions"'

# Kill session
alias tkill='tmux kill-session -t'

# Detach
alias td='tmux detach'

# --- Interactive Session Picker ---
if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
    ts() {
        local session
        session=$(tmux list-sessions -F '#{session_name}: #{session_windows} windows (#{session_attached} attached)' 2>/dev/null | \
            fzf --height=40% --prompt="Session: " | cut -d: -f1)
        if [[ -n "$session" ]]; then
            tmux switch-client -t "$session" 2>/dev/null || \
                tmux attach-session -t "$session"
        fi
    }
fi

# --- Development Layout ---
# Create a coding-focused tmux layout
tdev() {
    local name="${1:-dev}"
    local dir="${2:-$PWD}"

    tmux new-session -d -s "$name" -c "$dir"
    tmux rename-window -t "$name:0" 'editor'
    tmux new-window -t "$name" -n 'shell' -c "$dir"
    tmux new-window -t "$name" -n 'server' -c "$dir"
    tmux select-window -t "$name:0"
    tmux attach-session -t "$name"
}

# --- Window Helpers ---
alias tnw='tmux new-window'
alias trw='tmux rename-window'
alias tsplit='tmux split-window -h'
alias tvsplit='tmux split-window -v'
