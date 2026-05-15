#!/usr/bin/env bash
# ==============================================================================
# settings.sh — User-configurable settings
# ==============================================================================
# Override any of these in ~/.config/bash/local/local.sh
# ==============================================================================

# --- General ---
export BASHCFG_EDITOR="${EDITOR:-nano}"
export BASHCFG_PAGER="${PAGER:-less}"
export BASHCFG_BROWSER="${BROWSER:-}"

# --- Directories ---
export BASHCFG_PROJECTS_DIR="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"
export BASHCFG_WORKSPACE_DIR="${BASHCFG_WORKSPACE_DIR:-$HOME/workspace}"
export BASHCFG_NOTES_DIR="${BASHCFG_NOTES_DIR:-$HOME/notes}"
export BASHCFG_BACKUP_DIR="${BASHCFG_BACKUP_DIR:-$HOME/.backups}"
export BASHCFG_TRASH_DIR="${BASHCFG_TRASH_DIR:-$HOME/.trash}"
export BASHCFG_TEMPLATES_DIR="${BASHCFG_DIR}/data/templates"

# --- History ---
export BASHCFG_HISTSIZE=10000
export BASHCFG_HISTFILESIZE=20000
export BASHCFG_HIST_IGNORE="ls:cd:pwd:exit:clear:history"

# --- Prompt ---
export BASHCFG_PROMPT_THEME="${BASHCFG_PROMPT_THEME:-default}"
export BASHCFG_PROMPT_SHOW_GIT=1
export BASHCFG_PROMPT_SHOW_VENV=1
export BASHCFG_PROMPT_SHOW_EXIT_CODE=1
export BASHCFG_PROMPT_SHOW_JOBS=1
export BASHCFG_PROMPT_SHOW_TIME=0
export BASHCFG_PROMPT_SHOW_BATTERY=0
export BASHCFG_PROMPT_SHOW_HOSTNAME=0

# On SSH sessions, always show hostname
[[ $BASHCFG_IS_SSH -eq 1 ]] && BASHCFG_PROMPT_SHOW_HOSTNAME=1

# --- Safety ---
export BASHCFG_USE_TRASH=1            # Use trash instead of rm
export BASHCFG_CONFIRM_DANGEROUS=1    # Confirm before dangerous ops
export BASHCFG_BACKUP_ON_OVERWRITE=0  # Backup before overwriting files
export BASHCFG_TRASH_MAX_SIZE_MB=500  # Auto-clean trash above this size

# --- Performance ---
export BASHCFG_PROFILE_STARTUP="${BASHCFG_PROFILE_STARTUP:-0}"  # Set to 1 to profile
export BASHCFG_LAZY_LOAD="${BASHCFG_LAZY_LOAD:-1}"             # Lazy-load heavy modules
export BASHCFG_LOW_RESOURCE="${BASHCFG_LOW_RESOURCE:-0}"  # Set by platform.sh

# --- Logging ---
export BASHCFG_LOG_LEVEL=1            # 0=DEBUG 1=INFO 2=WARN 3=ERROR
export BASHCFG_LOG_MAX_SIZE=1024      # Max log file size in KB
export BASHCFG_LOG_COMMANDS=0         # Log all commands (privacy concern)

# --- Colors ---
export BASHCFG_COLORIZE=1             # Enable colored output
export BASHCFG_LS_COLORS=1            # Colorize ls output

# --- Project Management ---
export BASHCFG_DEFAULT_LICENSE="MIT"
export BASHCFG_DEFAULT_AUTHOR="${BASHCFG_DEFAULT_AUTHOR:-$(whoami)}"
export BASHCFG_PROJECT_ARCHIVE_DIR="${BASHCFG_BACKUP_DIR}/archives"

# --- AI Helpers ---
export BASHCFG_AI_SESSIONS_DIR="${BASHCFG_AI_SESSIONS_DIR:-$HOME/ai-sessions}"
export BASHCFG_OPENAI_MODEL="${BASHCFG_OPENAI_MODEL:-gpt-4}"

# --- Termux-Specific ---
if [[ $BASHCFG_IS_TERMUX -eq 1 ]]; then
    export BASHCFG_PROJECTS_DIR="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"
    export BASHCFG_STORAGE_DIR="/sdcard"
    export BASHCFG_WAKELOCK_ON_LONG_TASK=1
fi
