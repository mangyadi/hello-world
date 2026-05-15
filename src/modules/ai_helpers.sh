#!/usr/bin/env bash
# ==============================================================================
# ai_helpers.sh — AI-oriented workflow helpers
# ==============================================================================
# Prompt engineering, context loading, session management, and API helpers.
# Works with OpenAI API, local LLMs, and general AI coding workflows.
# ==============================================================================

[[ -n "$_BASHCFG_AI_LOADED" ]] && return 0
_BASHCFG_AI_LOADED=1

# --- AI Session Management ---
AI_SESSIONS_DIR="${BASHCFG_AI_SESSIONS_DIR:-$HOME/ai-sessions}"

# Create a new AI session folder with structure
ai_session() {
    local name="${1:-$(date +%Y%m%d_%H%M)}"
    local session_dir="${AI_SESSIONS_DIR}/${name}"

    _ensure_dir "$session_dir"
    _ensure_dir "${session_dir}/prompts"
    _ensure_dir "${session_dir}/responses"
    _ensure_dir "${session_dir}/context"
    _ensure_dir "${session_dir}/output"

    # Session metadata
    cat > "${session_dir}/session.md" << EOF
# AI Session: ${name}
Created: $(date '+%Y-%m-%d %H:%M')
Project: $(basename "$PWD")
Working Dir: $PWD

## Goal


## Notes


## Results

EOF

    cd "$session_dir"
    _print_success "AI Session: $session_dir"
}

# List AI sessions
ai_sessions() {
    if [[ -d "$AI_SESSIONS_DIR" ]]; then
        _print_header "AI Sessions"
        ls -1t "$AI_SESSIONS_DIR" 2>/dev/null | head -20
    else
        echo "No AI sessions. Use 'ai_session <name>' to create one."
    fi
}

# --- Project Context Loader ---
# Generate a context summary of the current project for AI prompts
ai_context() {
    local dir="${1:-.}"
    local output="${2:-/dev/stdout}"

    {
        echo "# Project Context"
        echo ""
        echo "## Directory: $(realpath "$dir" 2>/dev/null || echo "$dir")"
        echo "## Generated: $(date '+%Y-%m-%d %H:%M')"
        echo ""

        # Project structure
        echo "## Structure"
        echo '```'
        if command -v tree &>/dev/null; then
            tree -I 'node_modules|.git|__pycache__|target|dist|.venv|build' \
                -L 3 --filelimit 20 "$dir" 2>/dev/null
        else
            find "$dir" -maxdepth 3 -not -path '*/node_modules/*' \
                -not -path '*/.git/*' -not -path '*/__pycache__/*' \
                -not -path '*/target/*' -not -path '*/.venv/*' | \
                head -100 | sort
        fi
        echo '```'
        echo ""

        # README
        if [[ -f "${dir}/README.md" ]]; then
            echo "## README"
            echo '```'
            head -50 "${dir}/README.md"
            echo '```'
            echo ""
        fi

        # Package info
        if [[ -f "${dir}/package.json" ]]; then
            echo "## package.json (summary)"
            echo '```json'
            if [[ $BASHCFG_HAS_JQ -eq 1 ]]; then
                jq '{name, version, scripts, dependencies: (.dependencies // {} | keys), devDependencies: (.devDependencies // {} | keys)}' \
                    "${dir}/package.json" 2>/dev/null
            else
                head -30 "${dir}/package.json"
            fi
            echo '```'
            echo ""
        fi

        if [[ -f "${dir}/pyproject.toml" ]]; then
            echo "## pyproject.toml"
            echo '```toml'
            head -40 "${dir}/pyproject.toml"
            echo '```'
            echo ""
        fi

        if [[ -f "${dir}/Cargo.toml" ]]; then
            echo "## Cargo.toml"
            echo '```toml'
            cat "${dir}/Cargo.toml"
            echo '```'
            echo ""
        fi

        # Git status
        if [[ -d "${dir}/.git" ]]; then
            echo "## Git Status"
            echo '```'
            git -C "$dir" status -sb 2>/dev/null
            echo ""
            echo "Recent commits:"
            git -C "$dir" log --oneline -5 2>/dev/null
            echo '```'
        fi

    } > "$output"

    if [[ "$output" != "/dev/stdout" ]]; then
        _print_success "Context saved: $output"
    fi
}

# --- Codebase Summarizer ---
# Generate a summary of source files for AI context
ai_summarize() {
    local dir="${1:-.}"
    local max_lines="${2:-50}"

    echo "# Codebase Summary"
    echo ""

    local f
    find "$dir" -type f \
        \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.rs" \
           -o -name "*.sh" -o -name "*.go" -o -name "*.java" \) \
        -not -path '*/node_modules/*' \
        -not -path '*/.git/*' \
        -not -path '*/__pycache__/*' \
        -not -path '*/target/*' \
        -not -path '*/.venv/*' \
        -not -path '*/dist/*' 2>/dev/null | sort | while read -r f; do
        local lines
        lines=$(wc -l < "$f")
        echo "## ${f} (${lines} lines)"
        echo '```'
        head -n "$max_lines" "$f"
        if [[ $lines -gt $max_lines ]]; then
            echo "... (${lines} total lines, showing first ${max_lines})"
        fi
        echo '```'
        echo ""
    done
}

# --- Prompt Templates ---
# Save a prompt template
ai_prompt_save() {
    local name="$1"
    shift
    local content="$*"

    if [[ -z "$name" ]]; then
        echo "Usage: ai_prompt_save <name> <prompt_text>"
        echo "  or:  ai_prompt_save <name>  (opens editor)"
        return 1
    fi

    local prompts_dir="${BASHCFG_DIR}/data/prompts"
    _ensure_dir "$prompts_dir"

    if [[ -z "$content" ]]; then
        ${EDITOR:-nano} "${prompts_dir}/${name}.md"
    else
        echo "$content" > "${prompts_dir}/${name}.md"
        _print_success "Saved prompt: $name"
    fi
}

# Load and display a prompt template
ai_prompt_load() {
    local name="$1"
    local prompts_dir="${BASHCFG_DIR}/data/prompts"

    if [[ -z "$name" ]]; then
        echo "Available prompts:"
        ls -1 "$prompts_dir" 2>/dev/null | sed 's/\.md$//' | sed 's/^/  /'
        return
    fi

    local file="${prompts_dir}/${name}.md"
    if [[ -f "$file" ]]; then
        cat "$file"
        cat "$file" | _clip 2>/dev/null
    else
        _print_error "Prompt not found: $name"
    fi
}

# --- OpenAI API Helper ---
# Simple chat completion (requires OPENAI_API_KEY)
ai_ask() {
    if [[ -z "$OPENAI_API_KEY" ]]; then
        _print_error "OPENAI_API_KEY not set"
        return 1
    fi

    local prompt="$*"
    if [[ -z "$prompt" ]]; then
        echo "Usage: ai_ask <question>"
        return 1
    fi

    local model="${BASHCFG_OPENAI_MODEL:-gpt-4}"

    curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$(cat << EOF
{
    "model": "$model",
    "messages": [{"role": "user", "content": $(echo "$prompt" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || jq -n --arg p "$prompt" '$p' 2>/dev/null || echo "$prompt" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | { read -r l; echo "\"$l\""; })}],
    "max_tokens": 2000
}
EOF
)" | if [[ $BASHCFG_HAS_JQ -eq 1 ]]; then
        jq -r '.choices[0].message.content // .error.message // "Error"'
    else
        python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'choices' in data:
    print(data['choices'][0]['message']['content'])
elif 'error' in data:
    print('Error:', data['error']['message'])
" 2>/dev/null
    fi
}

# --- Log Parser ---
# Parse and summarize log files
ai_parse_log() {
    local logfile="$1"
    if [[ -z "$logfile" || ! -f "$logfile" ]]; then
        echo "Usage: ai_parse_log <logfile>"
        return 1
    fi

    _print_header "Log Summary: $logfile"
    echo "Lines: $(wc -l < "$logfile")"
    echo "Errors: $(grep -ci 'error\|exception\|fatal\|panic' "$logfile")"
    echo "Warnings: $(grep -ci 'warn' "$logfile")"
    echo ""

    echo "=== Errors ==="
    grep -i 'error\|exception\|fatal\|panic' "$logfile" | tail -10
    echo ""

    echo "=== Last 10 lines ==="
    tail -10 "$logfile"
}

# --- Task Runner ---
# Simple task runner from a tasks file
ai_task() {
    local tasks_file="${1:-tasks.md}"
    if [[ ! -f "$tasks_file" ]]; then
        echo "No tasks file. Create one with tasks as markdown checkboxes:"
        echo "  - [ ] Task 1"
        echo "  - [x] Task 2 (done)"
        return 1
    fi

    _print_header "Tasks"
    cat "$tasks_file"
}

# --- Local LLM Helpers ---
alias ollama_list='ollama list 2>/dev/null || echo "Ollama not installed"'
alias ollama_run='ollama run'
