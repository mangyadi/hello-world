#!/usr/bin/env bash
# ==============================================================================
# completion.sh — Tab completion configuration
# ==============================================================================

[[ -n "$_BASHCFG_COMPLETION_LOADED" ]] && return 0
_BASHCFG_COMPLETION_LOADED=1

# --- System Completions ---
# Load bash-completion if available
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
elif [[ -f /etc/bash_completion ]]; then
    source /etc/bash_completion
elif [[ $BASHCFG_IS_TERMUX -eq 1 && -f "${PREFIX}/share/bash-completion/bash_completion" ]]; then
    source "${PREFIX}/share/bash-completion/bash_completion"
fi

# --- Readline Configuration ---
# Case-insensitive completion
bind 'set completion-ignore-case on' 2>/dev/null

# Treat hyphens and underscores as equivalent
bind 'set completion-map-case on' 2>/dev/null

# Show all matches on ambiguous completion (no double-tab needed)
bind 'set show-all-if-ambiguous on' 2>/dev/null

# Add trailing slash to completed directories
bind 'set mark-directories on' 2>/dev/null
bind 'set mark-symlinked-directories on' 2>/dev/null

# Color completion based on file type
bind 'set colored-stats on' 2>/dev/null

# Show file type indicator in completion
bind 'set visible-stats on' 2>/dev/null

# Skip common prefix in completion list
bind 'set completion-prefix-display-length 3' 2>/dev/null

# Don't expand ~ to full path on completion
bind 'set expand-tilde off' 2>/dev/null

# --- Key Bindings ---
# Up/Down arrow for history search matching current input
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward' 2>/dev/null

# Ctrl+R for incremental reverse search (default, but explicit)
bind '"\C-r": reverse-search-history' 2>/dev/null

# Alt+. to insert last argument from previous command
bind '"\e.": yank-last-arg' 2>/dev/null

# --- Git Completion ---
# Load git completions if available
if [[ $BASHCFG_HAS_GIT -eq 1 ]]; then
    _bashcfg_git_comp_paths=(
        "/usr/share/bash-completion/completions/git"
        "/usr/lib/git-core/git-sh-prompt"
        "${PREFIX:-/usr}/share/git-core/contrib/completion/git-completion.bash"
    )
    for _bashcfg_gcp in "${_bashcfg_git_comp_paths[@]}"; do
        if [[ -f "$_bashcfg_gcp" ]]; then
            source "$_bashcfg_gcp"
            break
        fi
    done
fi

# --- Custom Completions ---

# Complete project names for project management functions
_complete_projects() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"
    if [[ -d "$projects_dir" ]]; then
        local projects
        projects=$(ls -1 "$projects_dir" 2>/dev/null)
        COMPREPLY=($(compgen -W "$projects" -- "$cur"))
    fi
}

# Apply completions to project commands
complete -F _complete_projects archive_project 2>/dev/null
complete -F _complete_projects backup_project 2>/dev/null
complete -F _complete_projects clean_project 2>/dev/null
complete -F _complete_projects project_stats 2>/dev/null
