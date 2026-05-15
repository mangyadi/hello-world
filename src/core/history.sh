#!/usr/bin/env bash
# ==============================================================================
# history.sh — Command history configuration
# ==============================================================================
# Optimized for searchability, deduplication, and persistence.
# ==============================================================================

[[ -n "$_BASHCFG_HISTORY_LOADED" ]] && return 0
_BASHCFG_HISTORY_LOADED=1

# History file location
export HISTFILE="${HOME}/.bash_history"

# History size
export HISTSIZE="${BASHCFG_HISTSIZE:-10000}"
export HISTFILESIZE="${BASHCFG_HISTFILESIZE:-20000}"

# Ignore duplicates and commands starting with space
export HISTCONTROL="ignoreboth:erasedups"

# Ignore common short commands
export HISTIGNORE="${BASHCFG_HIST_IGNORE:-ls:cd:pwd:exit:clear:history:bg:fg}"

# Timestamp in history
export HISTTIMEFORMAT="%F %T  "

# Append to history, don't overwrite
shopt -s histappend 2>/dev/null

# Save multi-line commands as one entry
shopt -s cmdhist 2>/dev/null

# Re-edit failed history substitution
shopt -s histreedit 2>/dev/null

# Verify history substitution before executing
shopt -s histverify 2>/dev/null

# Flush history after each command (prevents loss on crash)
PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND};}history -a"

# --- History Search Helpers ---

# Search history with grep
hgrep() {
    history | grep -i --color=auto "$@"
}

# Top 20 most used commands
htop_cmds() {
    local count="${1:-20}"
    history | awk '{CMD[$2]++} END {for (c in CMD) print CMD[c], c}' | \
        sort -rn | head -n "$count" | \
        awk '{printf "%4d  %s\n", $1, $2}'
}

# History stats
hstats() {
    echo "History entries: $(history | wc -l)"
    echo "History file: ${HISTFILE}"
    echo "Max in-memory: ${HISTSIZE}"
    echo "Max on-disk: ${HISTFILESIZE}"
    echo ""
    echo "Top 10 commands:"
    htop_cmds 10
}

# Interactive history search with fzf (if available)
if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
    hfzf() {
        local cmd
        cmd=$(history | fzf --tac --no-sort --height=40% --query="$*" | \
            sed 's/^[ ]*[0-9]*[ ]*//')
        if [[ -n "$cmd" ]]; then
            echo "$cmd"
            eval "$cmd"
        fi
    }
fi
