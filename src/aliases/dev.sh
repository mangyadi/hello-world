#!/usr/bin/env bash
# ==============================================================================
# dev.sh — Development workflow aliases
# ==============================================================================

# --- Python ---
alias py='python3'
alias py2='python2'
alias pip='pip3'
alias pipi='pip3 install'
alias pipu='pip3 install --upgrade'
alias pipf='pip3 freeze'
alias pipr='pip3 install -r requirements.txt'
alias pyserve='python3 -m http.server'

# --- Node ---
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nci='npm ci'
alias npx='npx --yes'

# Yarn
alias yi='yarn install'
alias ya='yarn add'
alias yad='yarn add --dev'
alias yr='yarn run'

# pnpm
alias pni='pnpm install'
alias pna='pnpm add'
alias pnr='pnpm run'

# --- Rust ---
alias cb='cargo build'
alias cr='cargo run'
alias ct='cargo test'
alias cc='cargo check'
alias ccl='cargo clippy'
alias cf='cargo fmt'
alias cnew='cargo new'
alias cdoc='cargo doc --open'

# --- Make ---
alias mk='make'
alias mkc='make clean'
alias mkt='make test'
alias mkb='make build'
alias mki='make install'

# --- Quick Servers ---
alias serve='python3 -m http.server 8000 2>/dev/null || npx serve'
alias json_server='python3 -m json.tool'

# --- File Watching ---
alias watchdir='inotifywait -m -r -e modify,create,delete .'

# --- Docker (if available) ---
alias dk='docker'
alias dkc='docker compose'
alias dkps='docker ps'
alias dkimg='docker images'
alias dkrm='docker rm $(docker ps -aq) 2>/dev/null'
alias dkrmi='docker rmi $(docker images -q) 2>/dev/null'
alias dkstop='docker stop $(docker ps -aq) 2>/dev/null'
alias dkprune='docker system prune -af'

# --- Encoding/Decoding ---
alias b64e='base64'
alias b64d='base64 -d'
alias urlencode='python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))"'
alias urldecode='python3 -c "import sys,urllib.parse;print(urllib.parse.unquote(sys.argv[1]))"'
alias jsonpp='python3 -m json.tool'

# --- Quick Checksums ---
alias sha256='sha256sum'
alias md5='md5sum'
