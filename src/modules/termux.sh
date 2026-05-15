#!/usr/bin/env bash
# ==============================================================================
# termux.sh — Termux/Android-specific optimizations
# ==============================================================================
# Loaded only on Termux. Handles Android paths, wake locks, storage,
# battery awareness, and proot interoperability.
# ==============================================================================

[[ -n "$_BASHCFG_TERMUX_LOADED" ]] && return 0
_BASHCFG_TERMUX_LOADED=1

# --- Storage Setup ---
# Ensure termux-setup-storage has been run
if [[ ! -d "$HOME/storage" ]] && command -v termux-setup-storage &>/dev/null; then
    echo "Run 'termux-setup-storage' to enable storage access."
fi

# --- Wake Lock Helpers ---
# Keep device awake during long tasks
wakelock_on() {
    if command -v termux-wake-lock &>/dev/null; then
        termux-wake-lock
        _print_success "Wake lock acquired"
    fi
}

wakelock_off() {
    if command -v termux-wake-unlock &>/dev/null; then
        termux-wake-unlock
        _print_success "Wake lock released"
    fi
}

# Run command with wake lock
with_wakelock() {
    if [[ -z "$*" ]]; then
        echo "Usage: with_wakelock <command>"
        return 1
    fi
    wakelock_on
    "$@"
    local exit_code=$?
    wakelock_off
    return $exit_code
}

# --- Battery Info ---
battery() {
    if command -v termux-battery-status &>/dev/null; then
        local status
        status=$(termux-battery-status 2>/dev/null)
        if [[ $BASHCFG_HAS_JQ -eq 1 ]]; then
            echo "$status" | jq -r '"Battery: \(.percentage)% (\(.status))"'
        else
            echo "$status"
        fi
    else
        _print_warn "termux-api not installed. Run: pkg install termux-api"
    fi
}

# --- Notification Helper ---
notify() {
    local title="${1:-BashCraft}"
    local content="${2:-Task complete}"
    if command -v termux-notification &>/dev/null; then
        termux-notification --title "$title" --content "$content"
    fi
}

# Notify on command completion
# Usage: long_command; notify_done
notify_done() {
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        notify "Success" "Command completed successfully"
    else
        notify "Failed" "Command exited with code $exit_code"
    fi
    return $exit_code
}

# --- Storage-Aware Cleanup ---
termux_cleanup() {
    _print_header "Termux Cleanup"

    # Show storage usage
    echo "Internal storage:"
    df -h "$HOME" 2>/dev/null | tail -1

    if [[ -d /sdcard ]]; then
        echo "External storage:"
        df -h /sdcard 2>/dev/null | tail -1
    fi

    echo ""

    # Clean pkg cache
    echo "Cleaning package cache..."
    pkg clean 2>/dev/null
    apt clean 2>/dev/null

    # Clean pip cache
    if [[ -d "$HOME/.cache/pip" ]]; then
        local size
        size=$(du -sh "$HOME/.cache/pip" 2>/dev/null | cut -f1)
        echo "Pip cache: $size"
        pip3 cache purge 2>/dev/null
    fi

    # Clean tmp
    if [[ -d "${PREFIX}/tmp" ]]; then
        local tmp_size
        tmp_size=$(du -sh "${PREFIX}/tmp" 2>/dev/null | cut -f1)
        echo "Tmp: $tmp_size"
        find "${PREFIX}/tmp" -mtime +3 -delete 2>/dev/null
    fi

    _print_success "Cleanup complete"
}

# --- proot-distro Helpers ---
if command -v proot-distro &>/dev/null; then
    alias pd='proot-distro'
    alias pdls='proot-distro list'
    alias pdlogin='proot-distro login'

    # Quick login to Ubuntu
    ubuntu() {
        proot-distro login ubuntu "$@"
    }

    # Run command in Ubuntu proot
    ubuntu_run() {
        proot-distro login ubuntu -- "$@"
    }
fi

# --- Android-Specific Shortcuts ---
# Open URL in Android browser
alias aopen='termux-open-url'

# Share file via Android share menu
ashare() {
    if command -v termux-share &>/dev/null; then
        termux-share "$@"
    else
        _print_warn "termux-api not installed"
    fi
}

# Copy to Android clipboard
alias acopy='termux-clipboard-set'
alias apaste='termux-clipboard-get'

# --- Vibrate on completion ---
vibrate() {
    command -v termux-vibrate &>/dev/null && termux-vibrate -d 200
}

# --- Safe Paths for Android ---
# Ensure $PREFIX paths work correctly
export TMPDIR="${PREFIX}/tmp"
_ensure_dir "$TMPDIR"

# --- Long-Running Session ---
# Start a session that survives screen off
persistent_session() {
    wakelock_on
    echo "Persistent session started. Use 'wakelock_off' when done."
    echo "Tip: Use tmux for session persistence: ta dev"
}

# --- Termux Package Shortcuts ---
alias pkgi='pkg install'
alias pkgu='pkg upgrade'
alias pkgs='pkg search'
alias pkgls='pkg list-installed'
