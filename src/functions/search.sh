#!/usr/bin/env bash
# ==============================================================================
# search.sh — Search and find utilities
# ==============================================================================

# --- Quick Find ---
# Find files by name pattern
ff() {
    local pattern="$1"
    local dir="${2:-.}"
    if [[ -z "$pattern" ]]; then
        echo "Usage: ff <pattern> [directory]"
        return 1
    fi
    find "$dir" -type f -iname "*${pattern}*" 2>/dev/null
}

# Find directories by name pattern
fd() {
    local pattern="$1"
    local dir="${2:-.}"
    if [[ -z "$pattern" ]]; then
        echo "Usage: fd <pattern> [directory]"
        return 1
    fi
    find "$dir" -type d -iname "*${pattern}*" 2>/dev/null
}

# --- Content Search ---
# Search file contents (uses ripgrep if available, falls back to grep)
search() {
    local pattern="$1"
    local dir="${2:-.}"
    if [[ -z "$pattern" ]]; then
        echo "Usage: search <pattern> [directory]"
        return 1
    fi

    if command -v rg &>/dev/null; then
        rg --color=auto --line-number "$pattern" "$dir"
    else
        grep -rn --color=auto "$pattern" "$dir"
    fi
}

# Search and replace in files
replace_in_files() {
    local search="$1"
    local replace="$2"
    local dir="${3:-.}"
    local ext="${4:-}"

    if [[ -z "$search" || -z "$replace" ]]; then
        echo "Usage: replace_in_files <search> <replace> [dir] [extension]"
        return 1
    fi

    _print_warn "Will replace '$search' with '$replace' in $dir"

    local find_cmd="find \"$dir\" -type f"
    [[ -n "$ext" ]] && find_cmd+=" -name \"*.$ext\""

    local count=0
    while IFS= read -r file; do
        if grep -l "$search" "$file" &>/dev/null; then
            if [[ "${BASHCFG_BACKUP_ON_OVERWRITE:-0}" == "1" ]]; then
                cp "$file" "${file}.bak"
            fi
            sed -i "s|${search}|${replace}|g" "$file"
            echo "  Modified: $file"
            ((count++))
        fi
    done < <(eval "$find_cmd" 2>/dev/null)

    _print_success "Modified $count file(s)"
}

# --- Interactive Search (fzf) ---
if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
    # Fuzzy file finder
    ffile() {
        local file
        file=$(find . -type f 2>/dev/null | fzf --height=40% --preview='head -50 {}' --query="$*")
        if [[ -n "$file" ]]; then
            ${EDITOR:-nano} "$file"
        fi
    }

    # Fuzzy directory changer
    fcd() {
        local dir
        dir=$(find . -type d 2>/dev/null | fzf --height=40% --query="$*")
        if [[ -n "$dir" ]]; then
            cd "$dir"
        fi
    }

    # Fuzzy grep (live search)
    fgrep_live() {
        if command -v rg &>/dev/null; then
            local result
            result=$(rg --color=always --line-number '' 2>/dev/null | \
                fzf --ansi --height=80% --query="$*" | cut -d: -f1-2)
            if [[ -n "$result" ]]; then
                local file line
                file=$(echo "$result" | cut -d: -f1)
                line=$(echo "$result" | cut -d: -f2)
                ${EDITOR:-nano} "+$line" "$file"
            fi
        else
            _print_warn "ripgrep (rg) not installed. Using basic grep."
            search "$@"
        fi
    }

    # Fuzzy process killer
    fkill() {
        local pid
        pid=$(ps aux | fzf --height=40% --header="Select process to kill" | awk '{print $2}')
        if [[ -n "$pid" ]]; then
            echo "Killing PID: $pid"
            kill "${1:--15}" "$pid"
        fi
    }
fi

# --- Code Search Helpers ---
# Find TODO/FIXME/HACK comments
todos() {
    local dir="${1:-.}"
    echo "=== TODOs ==="
    grep -rn --color=auto "TODO\|FIXME\|HACK\|XXX\|OPTIMIZE" "$dir" \
        --include="*.py" --include="*.js" --include="*.ts" \
        --include="*.rs" --include="*.sh" --include="*.go" \
        --include="*.java" --include="*.c" --include="*.cpp" \
        --include="*.rb" --include="*.md" 2>/dev/null
}

# Count lines of code
loc() {
    local dir="${1:-.}"
    _print_header "Lines of Code in $dir"

    local ext count
    for ext in py js ts jsx tsx rs sh go java c cpp rb; do
        count=$(find "$dir" -name "*.${ext}" -exec cat {} \; 2>/dev/null | wc -l)
        [[ $count -gt 0 ]] && printf "  %-8s %'d lines\n" ".$ext" "$count"
    done | sort -t' ' -k2 -rn
}
