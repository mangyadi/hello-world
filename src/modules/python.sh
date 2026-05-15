#!/usr/bin/env bash
# ==============================================================================
# python.sh — Python development helpers
# ==============================================================================
# Loaded only when python3 is available.
# ==============================================================================

[[ -n "$_BASHCFG_PYTHON_LOADED" ]] && return 0
_BASHCFG_PYTHON_LOADED=1

# --- Virtual Environment Management ---

# Create and activate venv
venv_create() {
    local name="${1:-.venv}"
    if [[ -d "$name" ]]; then
        _print_warn "Virtual environment already exists: $name"
        venv_activate "$name"
        return
    fi

    python3 -m venv "$name"
    source "${name}/bin/activate"
    pip install --upgrade pip setuptools wheel &>/dev/null
    _print_success "Created and activated: $name"
}

# Activate venv (auto-detect)
venv_activate() {
    local name="${1:-.venv}"
    local activate_paths=(
        "${name}/bin/activate"
        "venv/bin/activate"
        ".venv/bin/activate"
        "env/bin/activate"
    )
    local p
    for p in "${activate_paths[@]}"; do
        if [[ -f "$p" ]]; then
            source "$p"
            _print_success "Activated: $(basename "$(dirname "$(dirname "$p")")")"
            return 0
        fi
    done
    _print_error "No virtual environment found. Create with: venv_create"
    return 1
}

# Deactivate shortcut
alias vd='deactivate 2>/dev/null'
alias va='venv_activate'
alias vc='venv_create'

# --- Auto-activate venv on cd ---
# When entering a directory with a .venv, auto-activate it
_python_auto_venv() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        if [[ -f .venv/bin/activate ]]; then
            source .venv/bin/activate
        elif [[ -f venv/bin/activate ]]; then
            source venv/bin/activate
        fi
    elif [[ -n "$VIRTUAL_ENV" ]]; then
        # Deactivate if we left the project
        local project_dir
        project_dir=$(dirname "$VIRTUAL_ENV")
        if [[ "$PWD" != "$project_dir"* ]]; then
            deactivate 2>/dev/null
        fi
    fi
}

# Hook into cd
if [[ "${BASHCFG_PYTHON_AUTO_VENV:-1}" == "1" ]]; then
    cd() {
        builtin cd "$@" && _python_auto_venv
    }
fi

# --- Pip Helpers ---
# Install from requirements and freeze
pip_sync() {
    if [[ -f requirements.txt ]]; then
        pip install -r requirements.txt
    fi
    if [[ -f requirements-dev.txt ]]; then
        pip install -r requirements-dev.txt
    fi
}

pip_save() {
    pip freeze > requirements.txt
    _print_success "Saved to requirements.txt"
}

# --- Python REPL with auto-imports ---
alias ipy='python3 -c "
try:
    import IPython; IPython.start_ipython()
except ImportError:
    import code; code.interact()
"'

# --- Quick Python Script Runner ---
pyrun() {
    if [[ -z "$1" ]]; then
        echo "Usage: pyrun <script.py> [args...]"
        return 1
    fi
    python3 "$@"
}

# --- Python Project Utilities ---
# Run pytest with common flags
pytest_run() {
    python3 -m pytest -v --tb=short "$@"
}
alias pt='pytest_run'

# Run black formatter
pyfmt() {
    if command -v black &>/dev/null; then
        black "${@:-.}"
    elif command -v autopep8 &>/dev/null; then
        autopep8 --in-place --recursive "${@:-.}"
    else
        _print_warn "No formatter found. Install: pip install black"
    fi
}

# Run linter
pylint_run() {
    if command -v ruff &>/dev/null; then
        ruff check "${@:-.}"
    elif command -v flake8 &>/dev/null; then
        flake8 "${@:-.}"
    elif command -v pylint &>/dev/null; then
        pylint "${@:-.}"
    else
        _print_warn "No linter found. Install: pip install ruff"
    fi
}
alias pycheck='pylint_run'
