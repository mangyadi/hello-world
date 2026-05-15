#!/usr/bin/env bash
# ==============================================================================
# navigation.sh — Directory navigation aliases and shortcuts
# ==============================================================================

# --- Quick cd ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'

# --- Bookmarked Directories ---
alias home='cd ~'
alias proj='cd ${BASHCFG_PROJECTS_DIR}'
alias ws='cd ${BASHCFG_WORKSPACE_DIR}'
alias dl='cd ~/Downloads 2>/dev/null || cd ~/download 2>/dev/null'
alias docs='cd ~/Documents 2>/dev/null || cd ~/documents 2>/dev/null'
alias notes='cd ${BASHCFG_NOTES_DIR}'
alias tmp='cd /tmp'
alias conf='cd ${BASHCFG_DIR}'

# Termux storage shortcuts
if [[ $BASHCFG_IS_TERMUX -eq 1 ]]; then
    alias sdcard='cd /sdcard'
    alias dcim='cd /sdcard/DCIM 2>/dev/null'
    alias sdl='cd /sdcard/Download 2>/dev/null'
fi

# --- Directory Stack ---
alias dirs='dirs -v'      # Numbered directory stack
alias pushd='pushd'
alias popd='popd'

# --- Smart cd with history ---
# cd and immediately ls
cdl() {
    cd "$@" && ls
}

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# --- Bookmark System ---
# Save current directory as bookmark
bookmark() {
    local name="${1:-$(basename "$PWD")}"
    local bookmarks_file="${BASHCFG_DIR}/data/bookmarks"
    _ensure_dir "$(dirname "$bookmarks_file")"

    # Remove existing bookmark with same name
    if [[ -f "$bookmarks_file" ]]; then
        grep -v "^${name}=" "$bookmarks_file" > "${bookmarks_file}.tmp" 2>/dev/null
        mv "${bookmarks_file}.tmp" "$bookmarks_file"
    fi

    echo "${name}=${PWD}" >> "$bookmarks_file"
    _print_success "Bookmarked: ${name} → ${PWD}"
}

# Go to bookmark
goto() {
    local bookmarks_file="${BASHCFG_DIR}/data/bookmarks"
    if [[ ! -f "$bookmarks_file" ]]; then
        _print_warn "No bookmarks found. Use 'bookmark <name>' to create one."
        return 1
    fi

    if [[ -z "$1" ]]; then
        # List bookmarks or use fzf
        if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
            local selection
            selection=$(cat "$bookmarks_file" | fzf --height=40% --prompt="Bookmark: ")
            if [[ -n "$selection" ]]; then
                local dir="${selection#*=}"
                cd "$dir" || return 1
            fi
        else
            echo "Bookmarks:"
            cat "$bookmarks_file" | sed 's/=/ → /' | sed 's/^/  /'
        fi
        return
    fi

    local dir
    dir=$(grep "^${1}=" "$bookmarks_file" 2>/dev/null | head -1 | cut -d= -f2-)
    if [[ -n "$dir" && -d "$dir" ]]; then
        cd "$dir"
        _print_info "→ $dir"
    else
        _print_error "Bookmark '$1' not found or directory doesn't exist"
        return 1
    fi
}

# Remove bookmark
unbookmark() {
    local bookmarks_file="${BASHCFG_DIR}/data/bookmarks"
    [[ ! -f "$bookmarks_file" ]] && return
    grep -v "^${1}=" "$bookmarks_file" > "${bookmarks_file}.tmp"
    mv "${bookmarks_file}.tmp" "$bookmarks_file"
    _print_success "Removed bookmark: $1"
}

# List bookmarks
bookmarks() {
    local bookmarks_file="${BASHCFG_DIR}/data/bookmarks"
    if [[ -f "$bookmarks_file" && -s "$bookmarks_file" ]]; then
        _print_header "Bookmarks"
        while IFS='=' read -r name dir; do
            if [[ -d "$dir" ]]; then
                printf "  %-15s → %s\n" "$name" "$dir"
            else
                printf "  %-15s → %s (missing!)\n" "$name" "$dir"
            fi
        done < "$bookmarks_file"
    else
        echo "No bookmarks. Use 'bookmark <name>' to save current directory."
    fi
}

# Tab completion for goto/unbookmark
_complete_bookmarks() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local bookmarks_file="${BASHCFG_DIR}/data/bookmarks"
    if [[ -f "$bookmarks_file" ]]; then
        local names
        names=$(cut -d= -f1 "$bookmarks_file" 2>/dev/null)
        COMPREPLY=($(compgen -W "$names" -- "$cur"))
    fi
}
complete -F _complete_bookmarks goto 2>/dev/null
complete -F _complete_bookmarks unbookmark 2>/dev/null
