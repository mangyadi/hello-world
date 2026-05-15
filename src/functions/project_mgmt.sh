#!/usr/bin/env bash
# ==============================================================================
# project_mgmt.sh — Project lifecycle management
# ==============================================================================
# Functions for creating, archiving, backing up, cleaning, and navigating
# projects in a standardized multi-project workspace.
# ==============================================================================

# --- Create Project ---
# Scaffold a new project with common structure
create_project() {
    local name="$1"
    local type="${2:-basic}"
    local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"

    if [[ -z "$name" ]]; then
        echo "Usage: create_project <name> [type]"
        echo ""
        echo "Types: basic, python, node, rust, web, script"
        return 1
    fi

    local project_dir="${projects_dir}/${name}"
    if [[ -d "$project_dir" ]]; then
        _print_error "Project already exists: $project_dir"
        return 1
    fi

    _ensure_dir "$project_dir"
    cd "$project_dir" || return 1

    # Common files
    echo "# ${name}" > README.md
    echo "" >> README.md
    echo "Created: $(date +%Y-%m-%d)" >> README.md

    # .gitignore
    cat > .gitignore << 'EOF'
# OS
.DS_Store
Thumbs.db

# Editor
*.swp
*.swo
*~
.vscode/settings.json
.idea/

# Environment
.env
.env.local

# Build
dist/
build/
target/
__pycache__/
*.pyc
node_modules/
EOF

    # Type-specific scaffolding
    case "$type" in
        python)
            _ensure_dir src tests docs
            touch src/__init__.py tests/__init__.py
            cat > requirements.txt << 'EOF'
# Add your dependencies here
EOF
            cat > setup.py << EOF
from setuptools import setup, find_packages

setup(
    name="${name}",
    version="0.1.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
)
EOF
            cat > Makefile << 'EOF'
.PHONY: venv install test lint clean

venv:
	python3 -m venv .venv
	. .venv/bin/activate && pip install -r requirements.txt

install:
	pip install -e .

test:
	python -m pytest tests/

lint:
	python -m flake8 src/

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	rm -rf dist build *.egg-info
EOF
            echo ".venv/" >> .gitignore
            ;;

        node)
            cat > package.json << EOF
{
  "name": "${name}",
  "version": "0.1.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "license": "${BASHCFG_DEFAULT_LICENSE:-MIT}"
}
EOF
            echo 'console.log("Hello from '"${name}"'");' > index.js
            _ensure_dir src tests
            ;;

        rust)
            if command -v cargo &>/dev/null; then
                cd "$projects_dir"
                cargo init "$name" 2>/dev/null
                cd "$project_dir"
            else
                _ensure_dir src
                cat > src/main.rs << 'EOF'
fn main() {
    println!("Hello, world!");
}
EOF
            fi
            ;;

        web)
            _ensure_dir css js img
            cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <h1>Hello World</h1>
    <script src="js/main.js"></script>
</body>
</html>
EOF
            touch css/style.css js/main.js
            ;;

        script)
            _ensure_dir scripts logs data
            cat > scripts/main.sh << 'TMPL'
#!/usr/bin/env bash
set -euo pipefail

echo "Hello from main script"
TMPL
            chmod +x scripts/main.sh
            ;;

        basic|*)
            _ensure_dir src docs
            ;;
    esac

    # Initialize git
    if [[ $BASHCFG_HAS_GIT -eq 1 ]]; then
        git init -q
        git add -A
        git commit -q -m "Initial commit: scaffold ${type} project"
    fi

    # Register project
    _project_register "$name" "$type"

    _print_success "Created ${type} project: ${project_dir}"
    echo "  cd ${project_dir}"
}

# --- Archive Project ---
# Compress and move project to archives
archive_project() {
    local name="$1"
    local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"
    local archive_dir="${BASHCFG_PROJECT_ARCHIVE_DIR:-${BASHCFG_BACKUP_DIR}/archives}"

    if [[ -z "$name" ]]; then
        echo "Usage: archive_project <project_name>"
        return 1
    fi

    local project_dir="${projects_dir}/${name}"
    if [[ ! -d "$project_dir" ]]; then
        _print_error "Project not found: $project_dir"
        return 1
    fi

    _ensure_dir "$archive_dir"

    local timestamp
    timestamp=$(date +%Y%m%d)
    local archive_file="${archive_dir}/${name}_${timestamp}.tar.gz"

    _print_info "Archiving: $name..."
    tar czf "$archive_file" -C "$projects_dir" "$name" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        local size
        size=$(_file_size "$archive_file")
        _print_success "Archived: ${archive_file} ($size)"

        if _confirm "Remove original project directory?"; then
            command rm -rf "$project_dir"
            _print_info "Removed: $project_dir"
        fi
    else
        _print_error "Archive failed"
        return 1
    fi
}

# --- Backup Project ---
# Create a backup without removing the original
backup_project() {
    local name="$1"
    local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"

    if [[ -z "$name" ]]; then
        echo "Usage: backup_project <project_name>"
        return 1
    fi

    local project_dir="${projects_dir}/${name}"
    if [[ ! -d "$project_dir" ]]; then
        _print_error "Project not found: $project_dir"
        return 1
    fi

    smart_backup "$project_dir"
}

# --- Clone Template ---
# Create project from a saved template
clone_template() {
    local template="$1"
    local name="$2"
    local templates_dir="${BASHCFG_TEMPLATES_DIR}"
    local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"

    if [[ -z "$template" || -z "$name" ]]; then
        echo "Usage: clone_template <template_name> <new_project_name>"
        echo ""
        echo "Available templates:"
        if [[ -d "$templates_dir" ]]; then
            ls -1 "$templates_dir" 2>/dev/null | sed 's/^/  /'
        else
            echo "  (none — save a project as template with save_template)"
        fi
        return 1
    fi

    local template_dir="${templates_dir}/${template}"
    if [[ ! -d "$template_dir" ]]; then
        _print_error "Template not found: $template"
        return 1
    fi

    local dest="${projects_dir}/${name}"
    if [[ -d "$dest" ]]; then
        _print_error "Project already exists: $name"
        return 1
    fi

    cp -r "$template_dir" "$dest"

    # Re-init git
    if [[ -d "${dest}/.git" ]]; then
        command rm -rf "${dest}/.git"
    fi
    if [[ $BASHCFG_HAS_GIT -eq 1 ]]; then
        cd "$dest"
        git init -q && git add -A && git commit -q -m "Init from template: ${template}"
    fi

    _print_success "Created project '$name' from template '$template'"
}

# Save current project as template
save_template() {
    local name="${1:-$(basename "$PWD")}"
    local templates_dir="${BASHCFG_TEMPLATES_DIR}"

    _ensure_dir "$templates_dir"

    local dest="${templates_dir}/${name}"
    if [[ -d "$dest" ]]; then
        if ! _confirm "Template '$name' exists. Overwrite?"; then
            return 0
        fi
        command rm -rf "$dest"
    fi

    # Copy without .git, node_modules, etc.
    rsync -a --exclude='.git' --exclude='node_modules' --exclude='target' \
        --exclude='__pycache__' --exclude='.venv' --exclude='dist' \
        --exclude='build' --exclude='.env' \
        "$PWD/" "$dest/" 2>/dev/null || cp -r "$PWD" "$dest"

    _print_success "Saved template: $name"
}

# --- Clean Project ---
# Remove build artifacts and caches
clean_project() {
    local name="$1"
    local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"
    local project_dir

    if [[ -n "$name" ]]; then
        project_dir="${projects_dir}/${name}"
    else
        project_dir="$PWD"
    fi

    if [[ ! -d "$project_dir" ]]; then
        _print_error "Directory not found: $project_dir"
        return 1
    fi

    _print_info "Cleaning: $project_dir"

    local cleaned=0

    # Node
    if [[ -d "${project_dir}/node_modules" ]]; then
        local size
        size=$(du -sh "${project_dir}/node_modules" 2>/dev/null | cut -f1)
        command rm -rf "${project_dir}/node_modules"
        echo "  Removed node_modules ($size)"
        ((cleaned++))
    fi

    # Python
    find "$project_dir" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    find "$project_dir" -name "*.pyc" -delete 2>/dev/null
    if [[ -d "${project_dir}/.venv" ]]; then
        local size
        size=$(du -sh "${project_dir}/.venv" 2>/dev/null | cut -f1)
        echo "  .venv: $size (keeping — run 'rm -rf .venv' to remove)"
    fi

    # Rust
    if [[ -d "${project_dir}/target" ]]; then
        local size
        size=$(du -sh "${project_dir}/target" 2>/dev/null | cut -f1)
        command rm -rf "${project_dir}/target"
        echo "  Removed target/ ($size)"
        ((cleaned++))
    fi

    # Generic build dirs
    local d
    for d in dist build .cache .parcel-cache .next .nuxt; do
        if [[ -d "${project_dir}/${d}" ]]; then
            command rm -rf "${project_dir}/${d}"
            echo "  Removed ${d}/"
            ((cleaned++))
        fi
    done

    _print_success "Cleaned $cleaned artifact(s)"
}

# --- Search Projects ---
# Search across all projects for a pattern
search_project() {
    local pattern="$1"
    local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"

    if [[ -z "$pattern" ]]; then
        echo "Usage: search_project <pattern>"
        return 1
    fi

    _print_header "Searching projects for: $pattern"

    if command -v rg &>/dev/null; then
        rg --color=auto -l "$pattern" "$projects_dir" 2>/dev/null
    else
        grep -rl --color=auto "$pattern" "$projects_dir" 2>/dev/null
    fi
}

# --- Recent Projects ---
# Show recently modified projects
recent_projects() {
    local count="${1:-10}"
    local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"

    _print_header "Recently Modified Projects"

    if [[ ! -d "$projects_dir" ]]; then
        echo "Projects directory not found: $projects_dir"
        return 1
    fi

    find "$projects_dir" -maxdepth 1 -mindepth 1 -type d -printf '%T@ %f\n' 2>/dev/null | \
        sort -rn | head -n "$count" | \
        while read -r timestamp name; do
            local date_str
            date_str=$(date -d @"${timestamp%.*}" '+%Y-%m-%d %H:%M' 2>/dev/null || \
                       date -r "${timestamp%.*}" '+%Y-%m-%d %H:%M' 2>/dev/null || \
                       echo "unknown")
            printf "  %-30s %s\n" "$name" "$date_str"
        done
}

# --- Project Stats ---
# Show statistics for a project
project_stats() {
    local name="$1"
    local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"
    local project_dir

    if [[ -n "$name" ]]; then
        project_dir="${projects_dir}/${name}"
    else
        project_dir="$PWD"
        name=$(basename "$PWD")
    fi

    if [[ ! -d "$project_dir" ]]; then
        _print_error "Not found: $project_dir"
        return 1
    fi

    _print_header "Project Stats: $name"
    echo ""

    # Size
    echo "  Size: $(du -sh "$project_dir" 2>/dev/null | cut -f1)"

    # File count
    local total_files
    total_files=$(find "$project_dir" -type f 2>/dev/null | wc -l)
    echo "  Files: $total_files"

    # Directory count
    local total_dirs
    total_dirs=$(find "$project_dir" -type d 2>/dev/null | wc -l)
    echo "  Directories: $total_dirs"

    # Git info
    if [[ -d "${project_dir}/.git" ]]; then
        echo ""
        echo "  Git:"
        local branch commits
        branch=$(git -C "$project_dir" branch --show-current 2>/dev/null)
        commits=$(git -C "$project_dir" rev-list --count HEAD 2>/dev/null)
        echo "    Branch:  $branch"
        echo "    Commits: $commits"
        echo "    Last:    $(git -C "$project_dir" log -1 --format='%s (%cr)' 2>/dev/null)"
    fi

    # Language breakdown
    echo ""
    echo "  Languages:"
    loc "$project_dir" 2>/dev/null | head -10

    echo ""
}

# --- Project Switcher (fzf) ---
if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
    # Interactive project switcher
    pp() {
        local projects_dir="${BASHCFG_PROJECTS_DIR:-$HOME/projects}"
        if [[ ! -d "$projects_dir" ]]; then
            _print_error "Projects directory not found: $projects_dir"
            return 1
        fi

        local project
        project=$(ls -1 "$projects_dir" 2>/dev/null | \
            fzf --height=40% --prompt="Project: " --preview="ls -la ${projects_dir}/{}")

        if [[ -n "$project" ]]; then
            cd "${projects_dir}/${project}"
            _print_info "→ ${project}"
            ls
        fi
    }
fi

# --- Internal: Project Registry ---
_project_register() {
    local name="$1"
    local type="$2"
    local registry="${BASHCFG_DIR}/data/projects.list"

    _ensure_dir "$(dirname "$registry")"
    echo "$(date +%Y-%m-%d)|${name}|${type}|${BASHCFG_PROJECTS_DIR}/${name}" >> "$registry"
}

# List all registered projects
project_list() {
    local registry="${BASHCFG_DIR}/data/projects.list"
    if [[ -f "$registry" ]]; then
        _print_header "Registered Projects"
        printf "  %-12s %-20s %-8s %s\n" "Date" "Name" "Type" "Path"
        echo "  $(printf '%.0s─' {1..70})"
        while IFS='|' read -r date name type path; do
            local status="✔"
            [[ ! -d "$path" ]] && status="✖"
            printf "  %-12s %-20s %-8s %s %s\n" "$date" "$name" "$type" "$path" "$status"
        done < "$registry"
    else
        echo "No projects registered. Use 'create_project' to start."
    fi
}
