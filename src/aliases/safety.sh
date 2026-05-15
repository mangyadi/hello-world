#!/usr/bin/env bash
# ==============================================================================
# safety.sh — Safe defaults and dangerous command protection
# ==============================================================================

# --- Trash System ---
# Replace rm with a safe trash function when enabled
if [[ "${BASHCFG_USE_TRASH:-1}" == "1" ]]; then
    # Override rm with trash
    rm() {
        local trash_dir="${BASHCFG_TRASH_DIR:-$HOME/.trash}"
        local datestamp
        datestamp=$(date +%Y%m%d_%H%M%S)

        # Pass through flags to real rm for special cases
        if [[ "$1" == "-rf" && "$2" == "/" ]] || [[ "$1" == "-rf" && "$2" == "/*" ]]; then
            _print_error "BLOCKED: Attempted to rm -rf / — absolutely not."
            return 1
        fi

        # Handle flags
        local force=0 recursive=0 files=()
        local arg
        for arg in "$@"; do
            case "$arg" in
                -f|--force)     force=1 ;;
                -r|-R|--recursive) recursive=1 ;;
                -rf|-fr)        force=1; recursive=1 ;;
                -*)             ;; # Ignore other flags
                *)              files+=("$arg") ;;
            esac
        done

        if [[ ${#files[@]} -eq 0 ]]; then
            command rm "$@"
            return
        fi

        mkdir -p "$trash_dir" 2>/dev/null

        local f
        for f in "${files[@]}"; do
            if [[ ! -e "$f" ]]; then
                _print_warn "Not found: $f"
                continue
            fi

            local basename
            basename=$(basename "$f")
            local dest="${trash_dir}/${basename}_${datestamp}"

            mv "$f" "$dest" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                _print_info "Trashed: $f → $dest"
            else
                _print_error "Failed to trash: $f"
            fi
        done
    }

    # Empty trash
    trash_empty() {
        local trash_dir="${BASHCFG_TRASH_DIR:-$HOME/.trash}"
        if [[ ! -d "$trash_dir" ]] || [[ -z "$(ls -A "$trash_dir" 2>/dev/null)" ]]; then
            echo "Trash is empty."
            return
        fi

        local size
        size=$(du -sh "$trash_dir" 2>/dev/null | cut -f1)
        if _confirm "Empty trash? (${size} will be permanently deleted)"; then
            command rm -rf "${trash_dir:?}"/*
            _print_success "Trash emptied."
        fi
    }

    # List trash contents
    trash_list() {
        local trash_dir="${BASHCFG_TRASH_DIR:-$HOME/.trash}"
        if [[ -d "$trash_dir" ]] && [[ -n "$(ls -A "$trash_dir" 2>/dev/null)" ]]; then
            echo "Trash contents ($(du -sh "$trash_dir" | cut -f1)):"
            ls -lhA "$trash_dir"
        else
            echo "Trash is empty."
        fi
    }

    # Restore from trash
    trash_restore() {
        local trash_dir="${BASHCFG_TRASH_DIR:-$HOME/.trash}"
        if [[ ! -d "$trash_dir" ]]; then
            echo "Trash is empty."
            return
        fi

        local item
        if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
            item=$(ls -1 "$trash_dir" | fzf --height=40% --prompt="Restore: ")
        else
            echo "Items in trash:"
            ls -1 "$trash_dir" | nl
            read -rp "Enter number to restore: " num
            item=$(ls -1 "$trash_dir" | sed -n "${num}p")
        fi

        if [[ -n "$item" ]]; then
            # Remove timestamp suffix to get original name
            local original
            original=$(echo "$item" | sed 's/_[0-9]\{8\}_[0-9]\{6\}$//')
            mv "${trash_dir}/${item}" "./${original}"
            _print_success "Restored: ${original}"
        fi
    }

    # Auto-clean trash if over size limit
    _trash_auto_clean() {
        local trash_dir="${BASHCFG_TRASH_DIR:-$HOME/.trash}"
        local max_mb="${BASHCFG_TRASH_MAX_SIZE_MB:-500}"
        [[ ! -d "$trash_dir" ]] && return

        local size_kb
        size_kb=$(du -sk "$trash_dir" 2>/dev/null | cut -f1)
        local max_kb=$((max_mb * 1024))

        if [[ ${size_kb:-0} -gt $max_kb ]]; then
            # Remove oldest items until under limit
            log_warn "Trash exceeds ${max_mb}MB, cleaning oldest items..."
            find "$trash_dir" -maxdepth 1 -mtime +7 -delete 2>/dev/null
        fi
    }

    # Run auto-clean on shell start (non-blocking)
    _trash_auto_clean &>/dev/null &
    disown 2>/dev/null
fi

# Use real rm explicitly
alias realrm='command rm'

# --- Dangerous Command Confirmations ---
if [[ "${BASHCFG_CONFIRM_DANGEROUS:-1}" == "1" ]]; then
    # Confirm before chmod 777
    alias chmod='chmod --preserve-root'
    alias chown='chown --preserve-root'
    alias chgrp='chgrp --preserve-root'
fi
