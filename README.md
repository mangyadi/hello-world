# BashCraft

A production-grade modular `.bashrc` framework for professional developers.

Built for **Termux Android**, **proot-distro Ubuntu**, and daily coding workflows.

## Features

- **Modular architecture** — no monolithic `.bashrc`; every feature is a separate file
- **Conditional loading** — modules load only when their tools are installed
- **Platform-aware** — auto-detects Termux, proot-distro, WSL, native Linux, macOS
- **Low-resource friendly** — lazy loading, startup profiling, minimal RAM usage
- **Safe by default** — trash system, confirmation prompts, backup-on-overwrite
- **Plugin system** — drop-in extensibility with enable/disable support
- **AI-ready** — session folders, context loaders, prompt templates, OpenAI helpers
- **Developer workflow** — Python, Rust, Node.js, Git, Docker, tmux helpers
- **Fast startup** — typically <100ms cold, <50ms warm

## Quick Start

```bash
git clone https://github.com/your-user/bashrc-framework.git
cd bashrc-framework
bash install.sh
source ~/.bashrc
```

## Architecture

```
~/.config/bash/
├── init.sh                 # Main loader (sourced by .bashrc)
├── conf.d/
│   └── settings.sh         # User-configurable settings
├── core/                   # Always loaded
│   ├── colors.sh           # Color definitions
│   ├── exports.sh          # Environment variables + shell options
│   ├── paths.sh            # PATH construction (no duplicates)
│   ├── history.sh          # History config + search helpers
│   └── completion.sh       # Tab completion + key bindings
├── aliases/                # Always loaded
│   ├── general.sh          # ls, grep, disk, network, etc.
│   ├── navigation.sh       # cd shortcuts, bookmarks, directory stack
│   ├── git.sh              # Git aliases (gs, gl, gp, etc.)
│   ├── safety.sh           # Trash system, dangerous cmd protection
│   └── dev.sh              # Python, Node, Rust, Docker aliases
├── functions/              # Shell functions
│   ├── file_utils.sh       # safe_delete, smart_backup, extract_any, etc.
│   ├── project_mgmt.sh     # create/archive/backup/clean projects
│   ├── search.sh           # ff, fd, search, todos, loc
│   ├── system.sh           # sysinfo, meminfo, disk_cleanup, help
│   └── workspace.sh        # Session save/restore, workspaces, palette
├── modules/                # Conditionally loaded
│   ├── python.sh           # Venv management, auto-activate, formatters
│   ├── rust.sh             # Cargo helpers, clean-all, size analysis
│   ├── node.sh             # nvm lazy-load, pkg manager detect, scripts
│   ├── git_extras.sh       # Interactive branch picker, conventional commits
│   ├── docker.sh           # Container management, compose shortcuts
│   ├── tmux.sh             # Session management, dev layouts
│   ├── ssh.sh              # Agent, key management, tunnels
│   ├── ai_helpers.sh       # AI sessions, context, prompts, OpenAI API
│   └── termux.sh           # Android: wake lock, battery, proot, cleanup
├── plugins/                # User/third-party plugins
│   ├── README.md
│   └── example/
├── themes/                 # Prompt themes
│   ├── default.sh          # Full-featured (git, venv, exit code)
│   ├── minimal.sh          # Ultra-lightweight
│   └── powerline.sh        # Powerline-style segments
├── lib/                    # Internal libraries
│   ├── platform.sh         # Platform + capability detection
│   ├── utils.sh            # Shared utilities
│   ├── logging.sh          # Structured logging
│   └── loader.sh           # Module loading engine
├── local/                  # Machine-specific (not version-controlled)
│   └── local.sh
├── cache/                  # Cached data
├── logs/                   # Session logs
├── tmp/                    # Temporary files
└── data/                   # Persistent data
    ├── bookmarks           # Directory bookmarks
    ├── projects.list       # Project registry
    ├── sessions/           # Saved sessions
    ├── prompts/            # AI prompt templates
    └── templates/          # Project templates
```

## Load Order

1. **Platform detection** — sets `BASHCFG_IS_TERMUX`, `BASHCFG_IS_PROOT`, etc.
2. **Utility library** — shared helpers used by everything
3. **Logging** — structured log with rotation
4. **Loader engine** — module loading with profiling + error isolation
5. **Configuration** — user settings from `conf.d/`
6. **Core modules** — colors, exports, paths, history, completion
7. **Aliases** — general, navigation, git, safety, dev
8. **Functions** — file utils, project management, search, system, workspace
9. **Conditional modules** — Python, Rust, Node, Git, Docker, tmux, SSH, AI
10. **Prompt theme** — default, minimal, or powerline
11. **Plugins** — user/third-party extensions
12. **Local overrides** — machine-specific config

## Design Decisions

### Why not a monolithic .bashrc?
A single file becomes unmaintainable past ~200 lines. Modular files allow:
- Enable/disable features by adding/removing files
- Different configs per machine via `local/local.sh`
- Easy sharing — send someone just the modules they need
- Faster development — edit one module without risking others

### Why conditional loading?
Loading Python helpers on a machine without Python wastes startup time and pollutes the namespace. Each module declares its dependencies and is skipped if they're not met.

### Why lazy loading?
nvm alone adds 200-400ms to shell startup. BashCraft lazy-loads it: a stub function replaces `nvm`/`node`/`npm` and loads the real implementation on first use. Result: 0ms startup cost, <200ms first-use cost.

### Why platform detection in a separate file?
Checking `$BASHCFG_IS_TERMUX` is a variable read (nanoseconds). Checking `[[ -d /data/data/com.termux ]]` is a filesystem call (microseconds). Doing the filesystem call once and caching the result saves time across all modules.

### Why a trash system instead of rm?
`rm` is irreversible. The trash system moves files to `~/.trash/` with timestamps, allowing recovery. Auto-cleanup prevents unbounded growth. Use `realrm` when you need actual deletion.

## Performance

### Startup Profiling

```bash
BASHCFG_PROFILE_STARTUP=1 bash -i
```

This shows per-module load times:

```
═══ BashCraft v1.0.0 — Startup Profile ═══
  LOAD platform                   2ms
  LOAD utils                      1ms
  LOAD logging                    1ms
  LOAD loader                     1ms
  LOAD settings                   1ms
  LOAD colors                     1ms
  LOAD exports                    2ms
  LOAD paths                      1ms
  LOAD history                    1ms
  LOAD completion                 5ms
  LOAD general                    1ms
  ...
═══ Total startup: 45ms | Modules: 22 ═══
```

### Low-Resource Mode

On devices with <2GB RAM (common on Termux), BashCraft auto-enables low-resource mode:
- Heavy functions are lazy-loaded
- Minimal prompt theme is recommended
- Background cleanup is deferred

Override manually:
```bash
export BASHCFG_LOW_RESOURCE=1  # Force low-resource mode
```

## Security

- **No secrets in config files** — API keys go in `local/local.sh` (gitignored)
- **Trash instead of rm** — prevents accidental data loss
- **Confirmation for dangerous commands** — `chmod 777`, `chown` on `/`
- **`--preserve-root`** — on chmod/chown/chgrp by default
- **Automatic log rotation** — prevents disk fill from logging
- **Restrictive umask** — `022` by default

## Command Reference

### Navigation
| Command | Description |
|---------|-------------|
| `bookmark <name>` | Save current directory |
| `goto <name>` | Jump to bookmark |
| `bookmarks` | List all bookmarks |
| `cdl <dir>` | cd + ls |
| `mkcd <dir>` | mkdir + cd |
| `pp` | Interactive project switcher (fzf) |

### Files
| Command | Description |
|---------|-------------|
| `safe_delete <f>` | Move to trash |
| `smart_backup <f>` | Timestamped backup |
| `extract_any <f>` | Extract any archive format |
| `find_large_files` | Find large files |
| `duplicate_finder` | Find duplicate files |
| `quick_note <text>` | Timestamped note |
| `mkfile <f>` | Create file with language template |

### Projects
| Command | Description |
|---------|-------------|
| `create_project <name> [type]` | Scaffold new project (python/node/rust/web/script) |
| `archive_project <name>` | Compress and archive |
| `backup_project <name>` | Create backup |
| `clean_project [name]` | Remove build artifacts |
| `search_project <pattern>` | Search across projects |
| `recent_projects` | Recently modified |
| `project_stats [name]` | Show statistics |
| `project_list` | List registered projects |

### Git
| Alias | Command |
|-------|---------|
| `gs` | `git status -sb` |
| `gl` | `git log --oneline --graph -20` |
| `gd` | `git diff` |
| `ga` | `git add` |
| `gcm` | `git commit -m` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gwip` | Quick "work in progress" commit |
| `gconv` | Conventional commit helper |
| `gbf` | Interactive branch picker (fzf) |

### AI Helpers
| Command | Description |
|---------|-------------|
| `ai_session <name>` | Create structured AI session |
| `ai_context [dir]` | Generate project context for AI |
| `ai_summarize [dir]` | Summarize codebase files |
| `ai_prompt_save <name>` | Save prompt template |
| `ai_prompt_load <name>` | Load prompt template |
| `ai_ask <question>` | OpenAI API query (needs API key) |

### System
| Command | Description |
|---------|-------------|
| `sysinfo` | System information |
| `meminfo` | Memory usage |
| `disk_cleanup` | Free disk space |
| `port_check <port>` | Check port usage |
| `killport <port>` | Kill process on port |
| `palette` | Interactive command palette |

### Termux
| Command | Description |
|---------|-------------|
| `wakelock_on/off` | Manage wake lock |
| `with_wakelock <cmd>` | Run with wake lock |
| `battery` | Battery status |
| `notify <title> <msg>` | Android notification |
| `termux_cleanup` | Storage cleanup |
| `ubuntu` | Login to proot Ubuntu |

## Themes

Switch themes in `conf.d/settings.sh` or `local/local.sh`:

```bash
export BASHCFG_PROMPT_THEME="default"    # Full-featured
export BASHCFG_PROMPT_THEME="minimal"    # Ultra-light
export BASHCFG_PROMPT_THEME="powerline"  # Segment-based
```

## Plugins

Drop `.sh` files or directories into `~/.config/bash/plugins/`.

See [plugins/README.md](src/plugins/README.md) for the plugin API.

## Configuration

All settings are in `conf.d/settings.sh`. Override in `local/local.sh`:

```bash
# local/local.sh
export BASHCFG_PROMPT_THEME="minimal"
export BASHCFG_PROJECTS_DIR="$HOME/code"
export BASHCFG_USE_TRASH=0
export BASHCFG_PROMPT_SHOW_TIME=1
```

## Termux Setup

```bash
# Install prerequisites
pkg update && pkg upgrade
pkg install git python nodejs-lts rust fzf jq ripgrep tmux

# Install BashCraft
git clone https://github.com/your-user/bashrc-framework.git
cd bashrc-framework
bash install.sh

# Enable storage access
termux-setup-storage

# Install Termux API (for battery, notifications)
pkg install termux-api
```

## proot-distro Ubuntu Setup

```bash
# From Termux
pkg install proot-distro
proot-distro install ubuntu
proot-distro login ubuntu

# Inside Ubuntu proot
apt update && apt install -y git curl fzf jq ripgrep
git clone https://github.com/your-user/bashrc-framework.git
cd bashrc-framework
bash install.sh
```

## Uninstall

```bash
bash uninstall.sh
```

## License

MIT
