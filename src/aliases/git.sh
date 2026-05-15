#!/usr/bin/env bash
# ==============================================================================
# git.sh — Git aliases and shortcuts
# ==============================================================================

[[ $BASHCFG_HAS_GIT -ne 1 ]] && return 0

# --- Status & Info ---
alias gs='git status -sb'
alias gss='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias gdn='git diff --name-only'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all -30'
alias glp='git log --pretty=format:"%C(yellow)%h%C(reset) %C(green)%ad%C(reset) %s %C(blue)<%an>%C(reset)%C(red)%d%C(reset)" --date=short'
alias gbl='git blame'
alias gcount='git shortlog -sn'

# --- Branching ---
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gsw='git switch'
alias gswc='git switch -c'
alias gm='git merge'

# --- Staging & Committing ---
alias ga='git add'
alias gaa='git add -A'
alias gap='git add -p'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'

# --- Remote ---
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gf='git fetch'
alias gfa='git fetch --all --prune'

# --- Stash ---
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gstd='git stash drop'
alias gsts='git stash show -p'

# --- Cleanup ---
alias gclean='git clean -fd'
alias gprune='git remote prune origin'

# --- Quick Operations ---
alias gwip='git add -A && git commit -m "wip: work in progress"'
alias gsave='git add -A && git commit -m "chore: save point [skip ci]"'
alias gundo='git reset HEAD~1 --soft'

# --- Aliases for log ---
alias gtag='git tag -l --sort=-v:refname'
alias gremote='git remote -v'
