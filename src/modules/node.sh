#!/usr/bin/env bash
# ==============================================================================
# node.sh — Node.js / JavaScript development helpers
# ==============================================================================

[[ -n "$_BASHCFG_NODE_LOADED" ]] && return 0
_BASHCFG_NODE_LOADED=1

# --- Version Manager Loading ---
# nvm (lazy-loaded for performance)
if [[ -d "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    # Lazy-load nvm — only initialize when first called
    nvm() {
        unset -f nvm node npm npx
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        nvm "$@"
    }
    node() {
        unset -f nvm node npm npx
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        node "$@"
    }
    npm() {
        unset -f nvm node npm npx
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        npm "$@"
    }
    npx() {
        unset -f nvm node npm npx
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        npx "$@"
    }
fi

# fnm
if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd 2>/dev/null)"
fi

# --- Package Manager Detection ---
# Auto-detect and use the right package manager
pkg_run() {
    if [[ -f "pnpm-lock.yaml" ]]; then
        pnpm "$@"
    elif [[ -f "yarn.lock" ]]; then
        yarn "$@"
    elif [[ -f "bun.lockb" ]]; then
        bun "$@"
    else
        npm "$@"
    fi
}
alias p='pkg_run'

# --- Quick Scripts ---
# Run any script from package.json
nrs() {
    if [[ ! -f package.json ]]; then
        _print_error "No package.json found"
        return 1
    fi

    if [[ -z "$1" ]]; then
        # List available scripts
        echo "Available scripts:"
        if [[ $BASHCFG_HAS_JQ -eq 1 ]]; then
            jq -r '.scripts // {} | to_entries[] | "  \(.key): \(.value)"' package.json
        else
            python3 -c "
import json
with open('package.json') as f:
    scripts = json.load(f).get('scripts', {})
for k, v in scripts.items():
    print(f'  {k}: {v}')
" 2>/dev/null
        fi

        if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
            echo ""
            local script
            if [[ $BASHCFG_HAS_JQ -eq 1 ]]; then
                script=$(jq -r '.scripts // {} | keys[]' package.json | \
                    fzf --height=40% --prompt="Run script: ")
            fi
            if [[ -n "$script" ]]; then
                pkg_run run "$script"
            fi
        fi
    else
        pkg_run run "$@"
    fi
}

# --- Node Project Helpers ---
node_clean() {
    if [[ -d "node_modules" ]]; then
        local size
        size=$(du -sh node_modules 2>/dev/null | cut -f1)
        command rm -rf node_modules
        _print_success "Removed node_modules ($size)"
    fi
    # Also clean common build dirs
    local d
    for d in dist .next .nuxt .cache .parcel-cache; do
        [[ -d "$d" ]] && command rm -rf "$d" && echo "  Removed $d"
    done
}

# Fresh install
node_fresh() {
    node_clean
    pkg_run install
}

# --- Dependency Check ---
node_outdated() {
    pkg_run outdated 2>/dev/null
}

# --- Quick package.json info ---
pkg_info() {
    if [[ ! -f package.json ]]; then
        _print_error "No package.json found"
        return 1
    fi
    if [[ $BASHCFG_HAS_JQ -eq 1 ]]; then
        echo "Name:    $(jq -r '.name // "unnamed"' package.json)"
        echo "Version: $(jq -r '.version // "0.0.0"' package.json)"
        echo "Main:    $(jq -r '.main // "n/a"' package.json)"
        local deps dev_deps
        deps=$(jq -r '.dependencies // {} | length' package.json)
        dev_deps=$(jq -r '.devDependencies // {} | length' package.json)
        echo "Deps:    $deps production, $dev_deps dev"
    else
        head -10 package.json
    fi
}
