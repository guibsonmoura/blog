# Deployment (CI/CD)

## Pipelines

| Workflow | File | Trigger | What it does |
|----------|------|---------|--------------|
| **CI** | `.github/workflows/ci.yml` | PRs + push to `master` | brakeman, bundler-audit, importmap audit, rubocop, full test suite |
| **CD** | `.github/workflows/cd.yml` | push to `master` + manual (`workflow_dispatch`) | Build → release → push to GHCR → Docker Swarm deploy |

## CD flow

On every push to `master` (or a manual run), the CD pipeline:

1. **Computes a version** — CalVer `vYYYY.MM.DD-<run_number>` (unique, ordered, no manual bumping).
2. **Builds the production image** from `Dockerfile`, tagged `:latest` **and** `:<version>`.
3. **Pushes both tags to GHCR** → `ghcr.io/guibsonmoura/blog` (public image — see below).
4. **Creates a GitHub Release + git tag** for the version.
5. **Deploys to the VPS over SSH** — sources `.env`, runs `docker stack deploy` to roll the Swarm service to the new image.

```
push to master
   ├─ release ─ build ─ push ghcr.io/guibsonmoura/blog:{latest,vX} ─ GitHub Release
   └─ deploy (needs release) ─ ssh guibson@148.230.76.215:2222
        └─ docker stack deploy -c compose.yml blog   (rolling update)
```

## Target server

| | |
|---|---|
| Host / port | `148.230.76.215` : `2222` (SSH) |
| User | `guibson` |
| Stack directory | `/home/guibson/projetos/blog/` |
| Published app port | **3010** → container 80 |
| App URL | `http://148.230.76.215:3010` |
| Orchestrator | Docker Swarm (`docker stack deploy`) |

## GitHub secrets (already set)

| Secret | Purpose |
|--------|---------|
| `SSH_HOST` | `148.230.76.215` |
| `SSH_PORT` | `2222` |
| `SSH_USER` | `guibson` |
| `SSH_KEY` | private key (`id_ed25519`) for `guibson` |

No registry secret is needed — the GHCR image is **public**, and the build/push uses the built-in `GITHUB_TOKEN`.

## GHCR image must be public

The VPS pulls `ghcr.io/guibsonmoura/blog` with no auth, so the package has to be public. The package only exists **after the first push to `master`**, so make it public once, right after:

```bash
gh api --method PATCH /user/packages/container/blog/visibility -f visibility=public
```

Or: GitHub → your profile → Packages → `blog` → Package settings → Change visibility → **Public**.

## One-time VPS setup

As `guibson` on `148.230.76.215`:

```bash
# 1. Docker + swarm (guibson must be in the docker group)
docker swarm init                 # skip if this node is already a swarm manager

# 2. Stack directory + files
mkdir -p /home/guibson/projetos/blog
cd /home/guibson/projetos/blog
# copy deploy/compose.yml here as compose.yml
# copy deploy/.env.example here as .env and fill in real values:
#   SECRET_KEY_BASE  (docker run --rm ghcr.io/guibsonmoura/blog:latest ./bin/rails secret)
#   WORKSPACE_DATABASE_PASSWORD, JWT_SECRET
nano .env

# 3. First deploy
set -a; . ./.env; set +a
docker stack deploy -c compose.yml blog --resolve-image always
```

Verify:

```bash
docker service ls                 # blog_app 1/1, blog_db 1/1
curl -sf http://localhost:3010/up # 200
```

After this, every push to `master` rolls the stack automatically.

## What runs in the stack

- **`blog_app`** — the Rails image on port 3010. `bin/docker-entrypoint` runs `db:prepare` on boot, creating/migrating `workspace_production` + the `_cache` / `_queue` / `_cable` databases (Solid Cache/Queue/Cable). Uploads go to the `storage` volume (`ACTIVE_STORAGE_SERVICE=local`).
- **`blog_db`** — `postgres:17`, role `workspace`, data on the `pgdata` volume, internal-only (no published port).

## Rolling back

```bash
cd /home/guibson/projetos/blog
set -a; . ./.env; set +a
IMAGE_TAG=v2026.05.30-41 docker stack deploy -c compose.yml blog --resolve-image always
```

Available versions are under the repo's **Releases** and **Packages** tabs.

## Notes

- The `deploy` job fails until the VPS is provisioned (swarm init + stack dir + `.env`) and the image is public — expected, not a bug. The build/release/push half works on the first merge regardless.
- Env values are interpolated into the service spec, so they're visible via `docker service inspect`. For stronger isolation, migrate `SECRET_KEY_BASE` / `WORKSPACE_DATABASE_PASSWORD` to **Docker Swarm secrets** (`docker secret create` + `secrets:` in the stack + an entrypoint that exports them).
- `docker stack deploy` ignores `env_file` by design — that's why the deploy step sources `.env` into the shell first.
