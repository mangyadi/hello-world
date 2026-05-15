#!/usr/bin/env bash
# ==============================================================================
# system.sh — System information and maintenance utilities
# ==============================================================================

# --- System Info ---
sysinfo() {
    _print_header "System Information"
    echo "  Hostname:   $(hostname)"
    echo "  OS:         $(uname -sr)"
    echo "  Platform:   ${BASHCFG_PLATFORM}"
    echo "  Shell:      ${BASH_VERSION}"
    echo "  User:       $(whoami)"
    echo "  Uptime:     $(uptime -p 2>/dev/null || uptime)"
    echo "  CPU Cores:  ${BASHCFG_CPU_CORES}"
    echo "  RAM:        ${BASHCFG_TOTAL_RAM}MB"
    echo "  Disk:       $(df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
    echo "  Date:       $(date)"
}

# --- Memory Usage ---
meminfo() {
    _print_header "Memory Usage"
    if [[ -f /proc/meminfo ]]; then
        awk '
            /MemTotal/    {total=$2}
            /MemFree/     {free=$2}
            /MemAvailable/ {avail=$2}
            /Buffers/     {buf=$2}
            /^Cached/     {cache=$2}
            /SwapTotal/   {stotal=$2}
            /SwapFree/    {sfree=$2}
            END {
                used=total-free-buf-cache
                printf "  Total:     %d MB\n", total/1024
                printf "  Used:      %d MB\n", used/1024
                printf "  Available: %d MB\n", avail/1024
                printf "  Buffers:   %d MB\n", buf/1024
                printf "  Cached:    %d MB\n", cache/1024
                if (stotal > 0) {
                    printf "  Swap:      %d/%d MB\n", (stotal-sfree)/1024, stotal/1024
                }
            }
        ' /proc/meminfo
    else
        free -h 2>/dev/null || vm_stat 2>/dev/null
    fi
}

# --- Disk Cleanup ---
disk_cleanup() {
    _print_header "Disk Cleanup"
    local freed=0

    # Package manager caches
    if command -v apt &>/dev/null; then
        echo "Cleaning apt cache..."
        sudo apt autoremove -y 2>/dev/null && sudo apt clean 2>/dev/null
    elif [[ $BASHCFG_IS_TERMUX -eq 1 ]]; then
        echo "Cleaning pkg cache..."
        pkg clean 2>/dev/null
    fi

    # Python cache
    if [[ -d "$HOME/.cache/pip" ]]; then
        local pip_size
        pip_size=$(du -sh "$HOME/.cache/pip" 2>/dev/null | cut -f1)
        echo "Cleaning pip cache ($pip_size)..."
        pip3 cache purge 2>/dev/null
    fi

    # npm cache
    if command -v npm &>/dev/null; then
        echo "Cleaning npm cache..."
        npm cache clean --force 2>/dev/null
    fi

    # Python __pycache__
    echo "Cleaning __pycache__ directories..."
    find "$HOME" -maxdepth 5 -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    find "$HOME" -maxdepth 5 -name "*.pyc" -delete 2>/dev/null

    # Cargo cache (if very large)
    if [[ -d "$HOME/.cargo/registry" ]]; then
        local cargo_size
        cargo_size=$(du -sh "$HOME/.cargo/registry" 2>/dev/null | cut -f1)
        echo "Cargo registry: $cargo_size (run 'cargo cache -a' to clean)"
    fi

    # Trash
    local trash_dir="${BASHCFG_TRASH_DIR:-$HOME/.trash}"
    if [[ -d "$trash_dir" ]]; then
        local trash_size
        trash_size=$(du -sh "$trash_dir" 2>/dev/null | cut -f1)
        echo "Trash: $trash_size (run 'trash_empty' to clean)"
    fi

    # Log files
    echo "Cleaning old BashCraft logs..."
    log_cleanup 2>/dev/null

    _print_success "Cleanup complete"
}

# --- Weather (lightweight) ---
weather() {
    local city="${1:-}"
    curl -s "wttr.in/${city}?format=3" 2>/dev/null || echo "Weather unavailable"
}

# --- Cheat Sheet ---
cheat() {
    if [[ -z "$1" ]]; then
        echo "Usage: cheat <command>"
        return 1
    fi
    curl -s "cheat.sh/$1" 2>/dev/null | less -R
}

# --- Process Management ---
# Kill process by name
killbyname() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: killbyname <process_name>"
        return 1
    fi
    local pids
    pids=$(pgrep -f "$name" 2>/dev/null)
    if [[ -n "$pids" ]]; then
        echo "Killing processes matching '$name': $pids"
        kill $pids
    else
        echo "No processes found matching '$name'"
    fi
}

# --- Port Management ---
port_check() {
    local port="$1"
    if [[ -z "$port" ]]; then
        echo "Usage: port_check <port>"
        return 1
    fi
    ss -tulanp 2>/dev/null | grep ":${port} " || \
        netstat -tulanp 2>/dev/null | grep ":${port} " || \
        echo "Port $port is free"
}

killport() {
    local port="$1"
    if [[ -z "$port" ]]; then
        echo "Usage: killport <port>"
        return 1
    fi
    local pid
    pid=$(lsof -ti ":${port}" 2>/dev/null)
    if [[ -n "$pid" ]]; then
        kill -9 $pid
        _print_success "Killed process on port $port (PID: $pid)"
    else
        echo "No process found on port $port"
    fi
}

# --- BashCraft Help ---
help_bashcraft() {
    _print_header "BashCraft v${BASHCFG_VERSION} — Command Reference"
    echo ""
    echo "  Navigation:"
    echo "    bookmark <name>     Save current directory"
    echo "    goto <name>         Jump to bookmark"
    echo "    bookmarks           List all bookmarks"
    echo "    cdl <dir>           cd + ls"
    echo "    mkcd <dir>          mkdir + cd"
    echo ""
    echo "  Files:"
    echo "    safe_delete <f>     Safe delete (trash)"
    echo "    smart_backup <f>    Timestamped backup"
    echo "    extract_any <f>     Extract any archive"
    echo "    find_large_files    Find large files"
    echo "    duplicate_finder    Find duplicates"
    echo "    quick_note <text>   Quick timestamped note"
    echo "    mkfile <f>          Create file with template"
    echo ""
    echo "  Projects:"
    echo "    create_project      Create new project"
    echo "    archive_project     Archive a project"
    echo "    backup_project      Backup a project"
    echo "    clean_project       Clean build artifacts"
    echo "    search_project      Search across projects"
    echo "    recent_projects     Recently modified projects"
    echo "    project_stats       Project statistics"
    echo ""
    echo "  Search:"
    echo "    ff <pattern>        Find files"
    echo "    fd <pattern>        Find directories"
    echo "    search <pattern>    Search file contents"
    echo "    todos               Find TODO comments"
    echo "    loc                 Count lines of code"
    echo ""
    echo "  System:"
    echo "    sysinfo             System information"
    echo "    meminfo             Memory usage"
    echo "    disk_cleanup        Free disk space"
    echo "    port_check <port>   Check port usage"
    echo "    killport <port>     Kill process on port"
    echo ""
    echo "  Shell:"
    echo "    reload              Reload shell config"
    echo "    path                Show PATH entries"
    echo "    _startup_report     Show startup timing"
    echo "    _loaded_modules     Show loaded modules"
    echo ""
    echo "  Config: ${BASHCFG_DIR}"
    echo ""
}
