#!/usr/bin/env bash
# ==============================================================================
# docker.sh — Docker workflow helpers
# ==============================================================================

[[ -n "$_BASHCFG_DOCKER_LOADED" ]] && return 0
_BASHCFG_DOCKER_LOADED=1

# --- Container Management ---
# Interactive container selector
if [[ $BASHCFG_HAS_FZF -eq 1 ]]; then
    dkselect() {
        docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' | \
            fzf --header-lines=1 --height=40% | awk '{print $1}'
    }

    dksh() {
        local container
        container=$(dkselect)
        if [[ -n "$container" ]]; then
            docker exec -it "$container" /bin/sh -c 'command -v bash && exec bash || exec sh'
        fi
    }

    dklogs() {
        local container
        container=$(dkselect)
        if [[ -n "$container" ]]; then
            docker logs -f "$container"
        fi
    }
fi

# --- Docker Compose Shortcuts ---
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dcb='docker compose build'
alias dcps='docker compose ps'

# --- Cleanup ---
docker_cleanup() {
    _print_header "Docker Cleanup"
    echo "Removing stopped containers..."
    docker container prune -f 2>/dev/null
    echo "Removing dangling images..."
    docker image prune -f 2>/dev/null
    echo "Removing unused networks..."
    docker network prune -f 2>/dev/null
    echo "Removing unused volumes..."
    docker volume prune -f 2>/dev/null
    _print_success "Docker cleanup complete"
}

# Show docker disk usage
alias dkdf='docker system df'
