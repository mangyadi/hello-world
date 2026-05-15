#!/usr/bin/env bash
# ==============================================================================
# Example Plugin — Shows how to create a BashCraft plugin
# ==============================================================================

[[ -n "$_PLUGIN_EXAMPLE_LOADED" ]] && return 0
_PLUGIN_EXAMPLE_LOADED=1

# Plugin initialization
log_info "Example plugin loaded" 2>/dev/null

# Example function
example_hello() {
    echo "Hello from the example plugin!"
    echo "BashCraft version: ${BASHCFG_VERSION}"
    echo "Platform: ${BASHCFG_PLATFORM}"
}

# Example alias
alias example='example_hello'
