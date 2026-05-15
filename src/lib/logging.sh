#!/usr/bin/env bash
# ==============================================================================
# logging.sh — Lightweight logging framework
# ==============================================================================
# Provides structured logging with levels, file output, and colored console.
# Log files rotate automatically to prevent unbounded growth.
# ==============================================================================

[[ -n "$_BASHCFG_LOGGING_LOADED" ]] && return 0
_BASHCFG_LOGGING_LOADED=1

# Log directory
BASHCFG_LOG_DIR="${BASHCFG_DIR}/logs"
mkdir -p "$BASHCFG_LOG_DIR" 2>/dev/null

# Current session log
BASHCFG_SESSION_LOG="${BASHCFG_LOG_DIR}/session_$(date +%Y%m%d).log"

# Log levels: 0=DEBUG 1=INFO 2=WARN 3=ERROR
BASHCFG_LOG_LEVEL="${BASHCFG_LOG_LEVEL:-1}"

# Max log file size in KB (default 1MB)
BASHCFG_LOG_MAX_SIZE="${BASHCFG_LOG_MAX_SIZE:-1024}"

_log() {
    local level="$1" msg="$2"
    local level_num

    case "$level" in
        DEBUG) level_num=0 ;;
        INFO)  level_num=1 ;;
        WARN)  level_num=2 ;;
        ERROR) level_num=3 ;;
        *)     level_num=1 ;;
    esac

    # Skip if below configured level
    [[ $level_num -lt ${BASHCFG_LOG_LEVEL:-1} ]] && return 0

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[$timestamp] [$level] $msg"

    # Write to log file
    if [[ -w "${BASHCFG_LOG_DIR}" ]]; then
        echo "$entry" >> "$BASHCFG_SESSION_LOG" 2>/dev/null
    fi

    # Console output (only for WARN and ERROR in interactive shells)
    if [[ $BASHCFG_IS_INTERACTIVE -eq 1 && $level_num -ge 2 ]]; then
        case "$level" in
            WARN)  echo -e "\033[33m⚠ $msg\033[0m" >&2 ;;
            ERROR) echo -e "\033[31m✖ $msg\033[0m" >&2 ;;
        esac
    fi
}

log_debug() { _log "DEBUG" "$*"; }
log_info()  { _log "INFO"  "$*"; }
log_warn()  { _log "WARN"  "$*"; }
log_error() { _log "ERROR" "$*"; }

# Rotate logs if they exceed max size
_log_rotate() {
    local log_file="$1"
    [[ ! -f "$log_file" ]] && return

    local size_kb
    size_kb=$(du -k "$log_file" 2>/dev/null | cut -f1)
    if [[ ${size_kb:-0} -gt ${BASHCFG_LOG_MAX_SIZE} ]]; then
        mv "$log_file" "${log_file}.old" 2>/dev/null
        log_info "Rotated log: $log_file"
    fi
}

# Clean old logs (>7 days)
log_cleanup() {
    find "$BASHCFG_LOG_DIR" -name "*.log.old" -mtime +7 -delete 2>/dev/null
    find "$BASHCFG_LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null
    log_info "Cleaned old log files"
}

# Show recent log entries
log_show() {
    local lines="${1:-20}"
    if [[ -f "$BASHCFG_SESSION_LOG" ]]; then
        tail -n "$lines" "$BASHCFG_SESSION_LOG"
    else
        echo "No session log found."
    fi
}

# Rotate current session log on load
_log_rotate "$BASHCFG_SESSION_LOG"
