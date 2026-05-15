# BashCraft Plugins

Plugins extend BashCraft with additional functionality.

## Plugin Structure

Plugins can be:
1. **Single file**: `plugins/my_plugin.sh`
2. **Directory**: `plugins/my_plugin/init.sh` (with optional `plugin.conf`)

## Creating a Plugin

### Single File Plugin

```bash
# plugins/hello.sh
#!/usr/bin/env bash
# Plugin: hello
# Description: Example plugin

hello_world() {
    echo "Hello from plugin!"
}
```

### Directory Plugin

```
plugins/my_plugin/
├── init.sh         # Entry point (required)
├── plugin.conf     # Configuration (optional)
├── functions.sh    # Additional functions
└── README.md       # Documentation
```

### plugin.conf Format

```ini
# Plugin configuration
enabled=true
version=1.0.0
author=Your Name
description=What this plugin does
requires=git,python3
```

## Installing Plugins

1. Copy plugin file/directory to `~/.config/bash/plugins/`
2. Reload shell: `reload`

## Disabling a Plugin

For directory plugins, edit `plugin.conf`:
```ini
enabled=false
```

For file plugins, rename with `.disabled` extension:
```bash
mv plugins/hello.sh plugins/hello.sh.disabled
```
