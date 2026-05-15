#!/usr/bin/env bash
# ==============================================================================
# ssh.sh — SSH helpers and management
# ==============================================================================

[[ -n "$_BASHCFG_SSH_LOADED" ]] && return 0
_BASHCFG_SSH_LOADED=1

# --- SSH Agent ---
# Start ssh-agent if not running
_ssh_agent_start() {
    if [[ -z "$SSH_AUTH_SOCK" ]]; then
        local agent_file="$HOME/.ssh/agent_env"
        if [[ -f "$agent_file" ]]; then
            source "$agent_file" &>/dev/null
        fi
        if ! kill -0 "${SSH_AGENT_PID:-0}" &>/dev/null; then
            ssh-agent > "$agent_file" 2>/dev/null
            source "$agent_file" &>/dev/null
            # Auto-add default key
            ssh-add ~/.ssh/id_ed25519 2>/dev/null || \
                ssh-add ~/.ssh/id_rsa 2>/dev/null
        fi
    fi
}

# Start agent on interactive login (not in Termux by default — too slow)
if [[ $BASHCFG_IS_TERMUX -ne 1 ]]; then
    _ssh_agent_start
fi

# --- SSH Key Management ---
ssh_keygen_ed25519() {
    local comment="${1:-$(whoami)@$(hostname)}"
    local keyfile="${2:-$HOME/.ssh/id_ed25519}"
    ssh-keygen -t ed25519 -C "$comment" -f "$keyfile"
    _print_success "Generated key: $keyfile"
    echo "Public key:"
    cat "${keyfile}.pub"
}

# Copy public key to clipboard
ssh_pubkey() {
    local keyfile="${1:-$HOME/.ssh/id_ed25519.pub}"
    if [[ -f "$keyfile" ]]; then
        cat "$keyfile" | _clip
        _print_success "Public key copied to clipboard"
        cat "$keyfile"
    else
        _print_error "Key not found: $keyfile"
    fi
}

# --- SSH Config Helpers ---
# List configured hosts
ssh_hosts() {
    if [[ -f "$HOME/.ssh/config" ]]; then
        grep -i "^Host " "$HOME/.ssh/config" | awk '{print $2}' | grep -v '\*'
    fi
}

# Quick connect with fzf
if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
    sshf() {
        local host
        host=$(ssh_hosts | fzf --height=40% --prompt="SSH to: ")
        if [[ -n "$host" ]]; then
            ssh "$host"
        fi
    }
fi

# --- SSH Tunnel Helpers ---
ssh_tunnel() {
    local local_port="$1"
    local remote_host="$2"
    local remote_port="${3:-$local_port}"

    if [[ -z "$local_port" || -z "$remote_host" ]]; then
        echo "Usage: ssh_tunnel <local_port> <remote_host> [remote_port]"
        echo "Example: ssh_tunnel 8080 myserver 80"
        return 1
    fi

    echo "Tunneling localhost:${local_port} → ${remote_host}:${remote_port}"
    ssh -N -L "${local_port}:localhost:${remote_port}" "$remote_host"
}
