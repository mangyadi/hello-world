#!/usr/bin/env bash
# ==============================================================================
# loader.sh — Module loading engine
# ==============================================================================
# Handles sourcing of modules with:
#   - Load-order control
#   - Conditional loading (skip if dependency missing)
#   - Startup profiling
#   - Error isolation (one bad module won't break the shell)
#   - Lazy loading support
# ==============================================================================

[[ -n "$_BASHCFG_LOADER_LOADED" ]] && return 0
_BASHCFG_LOADER_LOADED=1

# Track loaded modules
declare -a _BASHCFG_LOADED_MODULES=()
declare -A _BASHCFG_LOAD_TIMES=()

# --- Core Loading Function ---
# Usage: _load_module <filepath> [required_command]
# If required_command is set, module is skipped when command is unavailable.
_load_module() {
    local filepath="$1"
    local required_cmd="${2:-}"
    local module_name

    module_name=$(basename "$filepath" .sh)

    # Skip if dependency not met
    if [[ -n "$required_cmd" ]] && ! command -v "$required_cmd" &>/dev/null; then
        [[ "${BASHCFG_PROFILE_STARTUP:-0}" == "1" ]] && \
            echo "  SKIP $module_name (missing: $required_cmd)"
        return 0
    fi

    # Skip if file doesn't exist
    if [[ ! -f "$filepath" ]]; then
        log_warn "Module not found: $filepath" 2>/dev/null
        return 1
    fi

    # Profile if enabled
    local start_ms=0
    if [[ "${BASHCFG_PROFILE_STARTUP:-0}" == "1" ]]; then
        start_ms=$(_now_ms)
    fi

    # Source with error isolation
    if source "$filepath" 2>/dev/null; then
        _BASHCFG_LOADED_MODULES+=("$module_name")

        if [[ "${BASHCFG_PROFILE_STARTUP:-0}" == "1" ]]; then
            local end_ms elapsed
            end_ms=$(_now_ms)
            elapsed=$(( end_ms - start_ms ))
            _BASHCFG_LOAD_TIMES["$module_name"]=$elapsed
            printf "  LOAD %-25s %4dms\n" "$module_name" "$elapsed"
        fi
    else
        log_error "Failed to load: $filepath" 2>/dev/null
        return 1
    fi
}

# --- Directory Loader ---
# Source all .sh files in a directory, sorted alphabetically.
# Usage: _load_dir <directory> [required_command]
_load_dir() {
    local dir="$1"
    local required_cmd="${2:-}"

    [[ ! -d "$dir" ]] && return 0

    local f
    for f in "$dir"/*.sh; do
        [[ -f "$f" ]] || continue
        _load_module "$f" "$required_cmd"
    done
}

# --- Lazy Loader ---
# Create a stub function that loads the real implementation on first call.
# Usage: _lazy_load <function_name> <source_file>
_lazy_load() {
    local func_name="$1"
    local source_file="$2"

    eval "${func_name}() {
        unset -f ${func_name}
        source \"${source_file}\"
        ${func_name} \"\$@\"
    }"
}

# --- Plugin Loader ---
# Load plugins from the plugins directory.
# Plugins can have an optional manifest: plugin_name/plugin.conf
_load_plugins() {
    local plugin_dir="${BASHCFG_DIR}/plugins"
    [[ ! -d "$plugin_dir" ]] && return 0

    local entry
    for entry in "$plugin_dir"/*/; do
        [[ -d "$entry" ]] || continue

        local plugin_name
        plugin_name=$(basename "$entry")
        local conf_file="${entry}plugin.conf"
        local init_file="${entry}init.sh"

        # Check if plugin is disabled
        if [[ -f "$conf_file" ]]; then
            local enabled
            enabled=$(grep -i "^enabled=" "$conf_file" 2>/dev/null | cut -d= -f2)
            if [[ "$enabled" == "false" || "$enabled" == "0" ]]; then
                [[ "${BASHCFG_PROFILE_STARTUP:-0}" == "1" ]] && \
                    echo "  SKIP plugin: $plugin_name (disabled)"
                continue
            fi
        fi

        # Load plugin init
        if [[ -f "$init_file" ]]; then
            _load_module "$init_file"
        elif [[ -f "${entry}${plugin_name}.sh" ]]; then
            _load_module "${entry}${plugin_name}.sh"
        fi
    done

    # Also load standalone .sh plugin files
    local f
    for f in "$plugin_dir"/*.sh; do
        [[ -f "$f" ]] || continue
        _load_module "$f"
    done
}

# --- Startup Report ---
# Show profiling results
_startup_report() {
    if [[ "${BASHCFG_PROFILE_STARTUP:-0}" != "1" ]]; then
        echo "Enable profiling: export BASHCFG_PROFILE_STARTUP=1"
        return
    fi

    echo ""
    _print_header "Startup Profile"
    echo "Modules loaded: ${#_BASHCFG_LOADED_MODULES[@]}"
    echo "Platform: $BASHCFG_PLATFORM"
    echo ""

    # Sort by load time (descending)
    local module
    for module in "${!_BASHCFG_LOAD_TIMES[@]}"; do
        printf "  %-25s %4dms\n" "$module" "${_BASHCFG_LOAD_TIMES[$module]}"
    done | sort -t' ' -k2 -rn

    echo ""
}

# --- Module Info ---
# List all loaded modules
_loaded_modules() {
    echo "Loaded modules (${#_BASHCFG_LOADED_MODULES[@]}):"
    local m
    for m in "${_BASHCFG_LOADED_MODULES[@]}"; do
        echo "  • $m"
    done
}
