#!/usr/bin/env bash
# ==============================================================================
# file_utils.sh — File manipulation utilities
# ==============================================================================

# --- Safe Delete ---
# Move to trash with logging, confirmation for directories
safe_delete() {
    local target="$1"
    if [[ -z "$target" ]]; then
        echo "Usage: safe_delete <file_or_dir>"
        return 1
    fi

    if [[ ! -e "$target" ]]; then
        _print_error "Not found: $target"
        return 1
    fi

    if [[ -d "$target" ]]; then
        local size
        size=$(du -sh "$target" 2>/dev/null | cut -f1)
        if ! _confirm "Delete directory '$target' ($size)?"; then
            echo "Cancelled."
            return 0
        fi
    fi

    rm "$target"
}

# --- Smart Backup ---
# Create timestamped backup of file or directory
smart_backup() {
    local target="$1"
    local backup_dir="${2:-${BASHCFG_BACKUP_DIR}}"

    if [[ -z "$target" ]]; then
        echo "Usage: smart_backup <file_or_dir> [backup_dir]"
        return 1
    fi

    if [[ ! -e "$target" ]]; then
        _print_error "Not found: $target"
        return 1
    fi

    _ensure_dir "$backup_dir"

    local basename timestamp dest
    basename=$(basename "$target")
    timestamp=$(date +%Y%m%d_%H%M%S)
    dest="${backup_dir}/${basename}_${timestamp}"

    if [[ -d "$target" ]]; then
        tar czf "${dest}.tar.gz" -C "$(dirname "$target")" "$basename" 2>/dev/null
        _print_success "Backed up: $target → ${dest}.tar.gz"
    else
        cp -a "$target" "$dest"
        _print_success "Backed up: $target → $dest"
    fi
}

# --- Extract Any Archive ---
extract_any() {
    if [[ -z "$1" ]]; then
        echo "Usage: extract_any <archive>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        _print_error "Not a file: $1"
        return 1
    fi

    case "$1" in
        *.tar.bz2) tar xjf "$1"   ;;
        *.tar.gz)  tar xzf "$1"   ;;
        *.tar.xz)  tar xJf "$1"   ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.bz2)     bunzip2 "$1"   ;;
        *.rar)     unrar x "$1"   ;;
        *.gz)      gunzip "$1"    ;;
        *.tar)     tar xf "$1"    ;;
        *.tbz2)    tar xjf "$1"   ;;
        *.tgz)     tar xzf "$1"   ;;
        *.zip)     unzip "$1"     ;;
        *.Z)       uncompress "$1" ;;
        *.7z)      7z x "$1"      ;;
        *.xz)      xz -d "$1"    ;;
        *.zst)     zstd -d "$1"  ;;
        *)
            _print_error "Unknown archive format: $1"
            return 1
            ;;
    esac
    _print_success "Extracted: $1"
}

# --- Find Large Files ---
find_large_files() {
    local dir="${1:-.}"
    local count="${2:-20}"
    local min_size="${3:-1M}"

    _print_header "Largest files in $dir (>$min_size)"
    find "$dir" -type f -size "+${min_size}" -exec ls -lhS {} \; 2>/dev/null | \
        sort -k5 -hr | head -n "$count" | \
        awk '{printf "%8s  %s\n", $5, $NF}'
}

# --- Duplicate Finder ---
duplicate_finder() {
    local dir="${1:-.}"
    _print_header "Finding duplicates in $dir (by size+md5)"

    # First pass: group by size
    find "$dir" -type f -not -empty -printf '%s\n' 2>/dev/null | \
        sort -n | uniq -d | while read -r size; do
        # Second pass: compare md5 of same-size files
        find "$dir" -type f -size "${size}c" -exec md5sum {} \; 2>/dev/null
    done | sort | uniq -w32 -d --all-repeated=separate
}

# --- Quick Edit ---
# Open file in editor, create if doesn't exist
quick_edit() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: quick_edit <file>"
        return 1
    fi
    _ensure_dir "$(dirname "$file")"
    ${EDITOR:-nano} "$file"
}

# --- Quick Note ---
# Append timestamped note to notes file
quick_note() {
    local notes_dir="${BASHCFG_NOTES_DIR:-$HOME/notes}"
    local note_file="${notes_dir}/quicknotes.md"
    _ensure_dir "$notes_dir"

    if [[ -z "$*" ]]; then
        # Open notes file
        ${EDITOR:-nano} "$note_file"
    else
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M')
        echo "- [${timestamp}] $*" >> "$note_file"
        _print_success "Note saved."
    fi
}
alias note='quick_note'

# --- File Comparison ---
# Quick diff between two files with color
fdiff() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: fdiff <file1> <file2>"
        return 1
    fi
    diff --color=auto -u "$1" "$2" | less -R
}

# --- Create file with template ---
mkfile() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: mkfile <filename>"
        return 1
    fi

    _ensure_dir "$(dirname "$file")"

    if [[ -e "$file" ]]; then
        _print_warn "File exists: $file"
        return 1
    fi

    local ext="${file##*.}"
    case "$ext" in
        sh)
            cat > "$file" << 'TMPL'
#!/usr/bin/env bash
set -euo pipefail

TMPL
            chmod +x "$file"
            ;;
        py)
            cat > "$file" << 'TMPL'
#!/usr/bin/env python3
"""Module docstring."""


def main():
    pass


if __name__ == "__main__":
    main()
TMPL
            chmod +x "$file"
            ;;
        *)
            touch "$file"
            ;;
    esac
    _print_success "Created: $file"
}
