#!/usr/bin/env bash
# ==============================================================================
# rust.sh — Rust development helpers
# ==============================================================================

[[ -n "$_BASHCFG_RUST_LOADED" ]] && return 0
_BASHCFG_RUST_LOADED=1

# --- Toolchain Management ---
alias rup='rustup update'
alias rcomp='rustup component list --installed'
alias rtarget='rustup target list --installed'

# --- Cargo Shortcuts ---
alias cw='cargo watch'                     # Needs cargo-watch
alias cwt='cargo watch -x test'
alias cwr='cargo watch -x run'
alias cwc='cargo watch -x check'
alias crel='cargo build --release'
alias cbench='cargo bench'
alias caudit='cargo audit 2>/dev/null'     # Needs cargo-audit
alias cupdate='cargo update'

# --- New Project with common setup ---
rust_new() {
    local name="$1"
    local type="${2:---bin}"  # --bin or --lib

    if [[ -z "$name" ]]; then
        echo "Usage: rust_new <name> [--bin|--lib]"
        return 1
    fi

    cargo new "$type" "$name" && cd "$name"
    _print_success "Created Rust project: $name"
}

# --- Quick test with filter ---
ctest() {
    if [[ -n "$1" ]]; then
        cargo test -- --test-threads=1 "$@"
    else
        cargo test
    fi
}

# --- Clean all Rust build artifacts in subdirectories ---
rust_clean_all() {
    local dir="${1:-.}"
    _print_info "Cleaning Rust target/ dirs in $dir..."
    local count=0
    while IFS= read -r target_dir; do
        local size
        size=$(du -sh "$target_dir" 2>/dev/null | cut -f1)
        command rm -rf "$target_dir"
        echo "  Removed: $target_dir ($size)"
        ((count++))
    done < <(find "$dir" -type d -name "target" -not -path "*/\.*" 2>/dev/null)
    _print_success "Cleaned $count target dir(s)"
}

# --- Cargo size analysis ---
cargo_size() {
    if command -v cargo-bloat &>/dev/null; then
        cargo bloat --release "$@"
    else
        echo "Install cargo-bloat: cargo install cargo-bloat"
        echo "Falling back to binary size:"
        ls -lh target/release/ 2>/dev/null | grep -v '\.d$'
    fi
}
