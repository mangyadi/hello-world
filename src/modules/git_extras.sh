#!/usr/bin/env bash
# ==============================================================================
# git_extras.sh — Advanced git functions
# ==============================================================================

[[ -n "$_BASHCFG_GIT_EXTRAS_LOADED" ]] && return 0
_BASHCFG_GIT_EXTRAS_LOADED=1

# --- Interactive Branch Switcher ---
if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
    gbf() {
        local branch
        branch=$(git branch -a --color=always | \
            fzf --ansi --height=40% --prompt="Branch: " | \
            sed 's/^[* ]*//' | sed 's|remotes/origin/||')
        if [[ -n "$branch" ]]; then
            git checkout "$branch"
        fi
    }

    # Interactive log viewer
    glf() {
        git log --oneline --graph --decorate --all --color=always | \
            fzf --ansi --no-sort --height=80% \
                --preview='git show --color=always {1}' \
                --bind='enter:execute(git show --color=always {1} | less -R)'
    }
fi

# --- Quick Commit with conventional format ---
gconv() {
    local type="$1"
    local msg="$2"
    local scope="$3"

    if [[ -z "$type" || -z "$msg" ]]; then
        echo "Usage: gconv <type> <message> [scope]"
        echo ""
        echo "Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build"
        return 1
    fi

    local commit_msg
    if [[ -n "$scope" ]]; then
        commit_msg="${type}(${scope}): ${msg}"
    else
        commit_msg="${type}: ${msg}"
    fi

    git commit -m "$commit_msg"
}

# --- Git Worktree Helpers ---
gwt_add() {
    local branch="$1"
    local dir="${2:-../${branch}}"
    if [[ -z "$branch" ]]; then
        echo "Usage: gwt_add <branch> [directory]"
        return 1
    fi
    git worktree add "$dir" "$branch"
    _print_success "Worktree added: $dir ($branch)"
}

gwt_list() {
    git worktree list
}

# --- Git Statistics ---
git_stats() {
    _print_header "Git Repository Stats"
    echo ""
    echo "Commits: $(git rev-list --count HEAD 2>/dev/null || echo 0)"
    echo "Branches: $(git branch | wc -l)"
    echo "Tags: $(git tag | wc -l)"
    echo "Contributors: $(git shortlog -sn 2>/dev/null | wc -l)"
    echo ""
    echo "Top contributors:"
    git shortlog -sn --no-merges 2>/dev/null | head -5
    echo ""
    echo "Recent activity:"
    git log --format="%ai %s" -5 2>/dev/null | while read -r line; do
        echo "  $line"
    done
}

# --- Git Diff Helpers ---
gdw() {
    git diff --word-diff "$@"
}

# Show what changed between two branches
gcompare() {
    local base="${1:-main}"
    local head="${2:-HEAD}"
    echo "=== Files changed: ${base}..${head} ==="
    git diff --stat "${base}..${head}"
    echo ""
    echo "=== Commits ==="
    git log --oneline "${base}..${head}"
}

# --- Undo Helpers ---
# Undo last commit (keep changes staged)
gundo() {
    git reset --soft HEAD~1
    _print_success "Undid last commit (changes kept staged)"
}

# Unstage everything
gunstage() {
    git reset HEAD -- "$@"
}

# Discard changes in a file (with confirmation)
gdiscard() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: gdiscard <file>"
        return 1
    fi
    if _confirm "Discard changes to '$file'?"; then
        git checkout -- "$file"
        _print_success "Discarded changes: $file"
    fi
}

# --- Git Init with defaults ---
ginit() {
    git init
    git add -A
    git commit -m "Initial commit"
    _print_success "Initialized repository with initial commit"
}

# --- Clone and cd ---
gclone() {
    local repo="$1"
    if [[ -z "$repo" ]]; then
        echo "Usage: gclone <repo_url>"
        return 1
    fi
    local dir_name
    dir_name=$(basename "$repo" .git)
    git clone "$repo" && cd "$dir_name"
}
