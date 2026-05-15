#!/usr/bin/env bash
# ==============================================================================
# .bashrc — BashCraft Framework Entry Point
# ==============================================================================
# This file replaces (or is appended to) your existing ~/.bashrc.
# All configuration lives in ~/.config/bash/ — this file just bootstraps it.
#
# Install:
#   cp bashrc ~/.bashrc  (or append to existing)
#   cp -r src/ ~/.config/bash/
#
# Profile startup:
#   BASHCFG_PROFILE_STARTUP=1 bash -i
# ==============================================================================

# Framework root (override if installed elsewhere)
export BASHCFG_DIR="${BASHCFG_DIR:-$HOME/.config/bash}"

# Load the framework
if [[ -f "${BASHCFG_DIR}/init.sh" ]]; then
    source "${BASHCFG_DIR}/init.sh"
else
    # Fallback: basic prompt if framework not installed
    PS1='\u@\h:\w\$ '
    echo "BashCraft not found at ${BASHCFG_DIR}. Run install.sh to set up."
fi
