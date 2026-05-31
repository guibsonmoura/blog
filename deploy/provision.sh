#!/usr/bin/env bash
#
# Idempotent VPS bootstrap for the blog Docker Swarm stack.
# Re-runnable: installs Docker + swarm if missing, creates the stack dir,
# uploads compose.yml, generates .env (only if absent — secrets are created
# ON the server and never printed), and deploys the stack.
#
# Usage (from the repo root):
#   SSH_KEY=~/.ssh/id_ed25519 bash deploy/provision.sh
#
# Overridable via env: SSH_HOST, SSH_PORT, SSH_USER, SSH_KEY, STACK_DIR
set -euo pipefail

SSH_HOST="${SSH_HOST:-148.230.76.215}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="${SSH_USER:-guibson}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
STACK_DIR="${STACK_DIR:-/home/guibson/projetos/blog}"
STACK_NAME="blog"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

remote() {
  ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=accept-new \
      -o IdentitiesOnly=yes "$SSH_USER@$SSH_HOST" "$@"
}

echo "==> 1/6 Docker present?"
remote 'command -v docker >/dev/null 2>&1 || (curl -fsSL https://get.docker.com | sh)'

echo "==> 2/6 Swarm initialised?"
remote 'docker info 2>/dev/null | grep -q "Swarm: active" || docker swarm init'

echo "==> 3/6 Stack directory"
remote "mkdir -p '$STACK_DIR'"

echo "==> 4/6 Upload compose.yml"
scp -i "$SSH_KEY" -P "$SSH_PORT" -o StrictHostKeyChecking=accept-new \
    "$SCRIPT_DIR/compose.yml" "$SSH_USER@$SSH_HOST:$STACK_DIR/compose.yml"

echo "==> 5/6 Ensure .env (generated on server, secrets stay on server)"
remote "test -f '$STACK_DIR/.env' && echo '   .env already exists — preserving it' || cat > '$STACK_DIR/.env' <<EOF
IMAGE_TAG=latest
SECRET_KEY_BASE=\$(openssl rand -hex 64)
WORKSPACE_DATABASE_PASSWORD=\$(openssl rand -hex 16)
JWT_SECRET=\$(openssl rand -hex 32)
ACTIVE_STORAGE_SERVICE=local
RAILS_LOG_LEVEL=info
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
ADMIN_PASSWORD=\$(openssl rand -hex 16)
EOF"

echo "==> 6/6 Deploy the stack"
remote "cd '$STACK_DIR' && set -a && . ./.env && set +a && \
        docker stack deploy -c compose.yml '$STACK_NAME' --resolve-image always --detach=false && \
        docker image prune -f"

echo ""
echo "Done. Check:  docker service ls   |   curl http://$SSH_HOST:3010/up"
