#!/usr/bin/env bash
# ==============================================================================
# workspace.sh — Workspace and session management
# ==============================================================================
# Session restore, workspace switching, environment auto-detection.
# ==============================================================================

# --- Session Restore ---
# Save current session state
session_save() {
    local name="${1:-last}"
    local session_file="${BASHCFG_DIR}/data/sessions/${name}.session"
    _ensure_dir "$(dirname "$session_file")"

    cat > "$session_file" << EOF
# BashCraft Session: ${name}
# Saved: $(date)
SESSION_DIR="$PWD"
SESSION_VENV="${VIRTUAL_ENV:-}"
SESSION_HISTORY_POS=$(history 1 | awk '{print $1}')
EOF

    _print_success "Session saved: $name"
}

# Restore session
session_restore() {
    local name="${1:-last}"
    local session_file="${BASHCFG_DIR}/data/sessions/${name}.session"

    if [[ ! -f "$session_file" ]]; then
        _print_error "Session not found: $name"
        return 1
    fi

    source "$session_file"

    # Restore directory
    if [[ -n "$SESSION_DIR" && -d "$SESSION_DIR" ]]; then
        cd "$SESSION_DIR"
    fi

    # Restore venv
    if [[ -n "$SESSION_VENV" && -d "$SESSION_VENV" ]]; then
        source "${SESSION_VENV}/bin/activate" 2>/dev/null
    fi

    _print_success "Session restored: $name (dir: $SESSION_DIR)"
}

# List saved sessions
session_list() {
    local sessions_dir="${BASHCFG_DIR}/data/sessions"
    if [[ -d "$sessions_dir" ]]; then
        _print_header "Saved Sessions"
        for f in "$sessions_dir"/*.session; do
            [[ -f "$f" ]] || continue
            local name
            name=$(basename "$f" .session)
            local dir
            dir=$(grep "SESSION_DIR=" "$f" | cut -d'"' -f2)
            printf "  %-15s → %s\n" "$name" "$dir"
        done
    else
        echo "No saved sessions."
    fi
}

# Auto-save session on exit
_session_auto_save() {
    session_save "last" 2>/dev/null
}
trap _session_auto_save EXIT

# --- Workspace Manager ---
# Switch between predefined workspace configurations
workspace() {
    local name="$1"
    local workspaces_file="${BASHCFG_DIR}/data/workspaces.conf"

    if [[ -z "$name" ]]; then
        if [[ -f "$workspaces_file" ]]; then
            _print_header "Workspaces"
            grep "^\[" "$workspaces_file" | tr -d '[]'
        else
            echo "No workspaces configured."
            echo "Create ${workspaces_file} with sections like:"
            echo "  [myproject]"
            echo "  dir=/path/to/project"
            echo "  venv=.venv"
            echo "  run=npm start"
        fi
        return
    fi

    if [[ ! -f "$workspaces_file" ]]; then
        _print_error "No workspaces file: $workspaces_file"
        return 1
    fi

    # Parse workspace section
    local in_section=0 ws_dir="" ws_venv="" ws_run="" ws_env=""
    while IFS= read -r line; do
        if [[ "$line" == "[${name}]" ]]; then
            in_section=1
            continue
        elif [[ "$line" =~ ^\[.*\] ]]; then
            in_section=0
            continue
        fi

        if [[ $in_section -eq 1 ]]; then
            case "$line" in
                dir=*)  ws_dir="${line#dir=}" ;;
                venv=*) ws_venv="${line#venv=}" ;;
                run=*)  ws_run="${line#run=}" ;;
                env=*)  ws_env="${line#env=}" ;;
            esac
        fi
    done < "$workspaces_file"

    if [[ -z "$ws_dir" ]]; then
        _print_error "Workspace '$name' not found"
        return 1
    fi

    # Switch to workspace
    cd "$ws_dir" || return 1
    _print_info "Workspace: $name → $ws_dir"

    # Activate venv if specified
    if [[ -n "$ws_venv" && -f "${ws_venv}/bin/activate" ]]; then
        source "${ws_venv}/bin/activate"
        echo "  Activated: $ws_venv"
    fi

    # Load env file
    if [[ -n "$ws_env" && -f "$ws_env" ]]; then
        set -a
        source "$ws_env"
        set +a
        echo "  Loaded: $ws_env"
    fi

    # Run startup command
    if [[ -n "$ws_run" ]]; then
        echo "  Run: $ws_run"
    fi
}

# --- Automatic Environment Switching ---
# Detect and load project-specific env on cd
_auto_env_switch() {
    # .env file
    if [[ -f .env && "${BASHCFG_AUTO_DOTENV:-0}" == "1" ]]; then
        set -a
        source .env 2>/dev/null
        set +a
    fi

    # .nvmrc / .node-version
    if [[ -f .nvmrc || -f .node-version ]] && command -v nvm &>/dev/null; then
        nvm use 2>/dev/null
    fi

    # .python-version
    if [[ -f .python-version ]] && command -v pyenv &>/dev/null; then
        pyenv activate 2>/dev/null
    fi

    # .ruby-version
    if [[ -f .ruby-version ]] && command -v rbenv &>/dev/null; then
        rbenv shell "$(cat .ruby-version)" 2>/dev/null
    fi
}

# --- Command Palette ---
# Interactive command launcher
command_palette() {
    if [[ $BASHCFG_HAS_FZF -ne 1 ]]; then
        _print_warn "fzf required for command palette"
        return 1
    fi

    local commands=(
        "create_project:Create a new project"
        "archive_project:Archive an existing project"
        "bookmark:Bookmark current directory"
        "goto:Jump to bookmark"
        "ai_session:Create AI session"
        "ai_context:Generate project context"
        "sysinfo:System information"
        "meminfo:Memory usage"
        "disk_cleanup:Free disk space"
        "find_large_files:Find large files"
        "duplicate_finder:Find duplicate files"
        "todos:Find TODO comments"
        "loc:Count lines of code"
        "project_stats:Project statistics"
        "recent_projects:Recently modified projects"
        "hstats:History statistics"
        "reload:Reload shell config"
        "_startup_report:Startup profile"
        "_loaded_modules:List loaded modules"
    )

    local selection
    selection=$(printf '%s\n' "${commands[@]}" | \
        awk -F: '{printf "%-25s %s\n", $1, $2}' | \
        fzf --height=60% --prompt="Command: " --header="BashCraft Command Palette")

    if [[ -n "$selection" ]]; then
        local cmd
        cmd=$(echo "$selection" | awk '{print $1}')
        eval "$cmd"
    fi
}
alias palette='command_palette'

# --- Cron Helper ---
cron_edit() {
    crontab -e
}

cron_list() {
    _print_header "Current Crontab"
    crontab -l 2>/dev/null || echo "No crontab entries"
}

cron_add() {
    local schedule="$1"
    local command="$2"
    if [[ -z "$schedule" || -z "$command" ]]; then
        echo "Usage: cron_add '<schedule>' '<command>'"
        echo "Example: cron_add '0 2 * * *' '/path/to/backup.sh'"
        return 1
    fi
    (crontab -l 2>/dev/null; echo "$schedule $command") | crontab -
    _print_success "Added cron: $schedule $command"
}

# --- Script Runner ---
# Run scripts from a project's scripts/ directory
run_script() {
    local scripts_dir="./scripts"
    [[ ! -d "$scripts_dir" ]] && scripts_dir="./bin"
    [[ ! -d "$scripts_dir" ]] && { echo "No scripts/ or bin/ directory found"; return 1; }

    if [[ -z "$1" ]]; then
        if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
            local script
            script=$(find "$scripts_dir" -type f -executable 2>/dev/null | \
                fzf --height=40% --prompt="Run script: ")
            [[ -n "$script" ]] && "$script"
        else
            echo "Available scripts:"
            find "$scripts_dir" -type f -executable 2>/dev/null | sed 's|^\./||'
        fi
    else
        local script="${scripts_dir}/${1}"
        if [[ -x "$script" ]]; then
            shift
            "$script" "$@"
        else
            _print_error "Script not found or not executable: $script"
        fi
    fi
}
