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

## One-time VPS setup — as code

The bootstrap is captured in **`deploy/provision.sh`** (idempotent). Run it once from the repo root:

```bash
SSH_KEY=~/.ssh/id_ed25519 bash deploy/provision.sh
```

It connects to the VPS and, idempotently:
1. installs Docker if missing, 2. `docker swarm init` if not already a manager,
3. creates `/home/guibson/projetos/blog`, 4. uploads `compose.yml`,
5. generates `.env` **only if absent** — secrets (`SECRET_KEY_BASE`, `WORKSPACE_DATABASE_PASSWORD`,
`JWT_SECRET`) are created **on the server** with `openssl`, never printed or stored locally,
6. runs the first `docker stack deploy`.

Re-running is safe: it won't overwrite an existing `.env`, and it just re-rolls the stack.

### Why a script and not Terraform

The VPS already exists and isn't managed through a cloud provider API, so Terraform here would
reduce to `null_resource` + `remote-exec` provisioners — an anti-pattern (Terraform isn't a
config-management tool). `provision.sh` is the right "setup as code": versioned, idempotent,
reviewable. If the host is ever recreated via a provider with an API (Hetzner/DO/AWS…), add a
Terraform module for the VM lifecycle and keep `provision.sh` as the in-VM bootstrap.

### Bootstrap vs ongoing deploys

`provision.sh` is the **one-time** bootstrap. After that the **CD pipeline** owns every deploy: it
`scp`s the current `deploy/compose.yml` to the server (repo = source of truth) and rolls the stack
to the new image. You don't run `provision.sh` again unless rebuilding the box.

### Manual equivalent (if not using the script)

```bash
docker swarm init
mkdir -p /home/guibson/projetos/blog && cd /home/guibson/projetos/blog
# copy deploy/compose.yml → compose.yml ; deploy/.env.example → .env (fill secrets)
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

- **`blog_app`** — the Rails image on port 3010. `bin/docker-entrypoint` runs `db:prepare` on boot, creating/migrating `workspace_production` + the `_cache` / `_queue` / `_cable` databases (Solid Cache/Queue/Cable). Uploads go to **MinIO** (`ACTIVE_STORAGE_SERVICE=minio`, see below). Reaches the translator at `http://translator:8000`.
- **`blog_db`** — `postgres:17`, role `workspace`, data on the `pgdata` volume, internal-only (no published port).
- **`blog_translator`** — Opus-MT PT→EN service (`ghcr.io/guibsonmoura/blog-translator:latest`), internal-only. Memory: 1 GB reserved / 2.5 GB limit.
- **`blog_minio`** — S3-compatible object storage for Active Storage (cover images). Internal-only (no published port); the app reaches it at `http://minio:9000` and serves files **proxied through Rails** (`config.active_storage.resolve_model_to_route`), so the browser never talks to MinIO directly. Data on the `minio` volume. Memory limit 512 MB.
- **`blog_createbuckets`** — one-shot `minio/mc` task (`restart_policy: none`); waits for MinIO, creates the `blog-production` bucket (private), then exits — so it shows `0/1` in `docker service ls`, which is normal. Idempotent (`mb --ignore-existing`), so re-running `stack deploy` is safe.

### Object storage (MinIO)

Production stores uploads in the in-stack MinIO service rather than on a local disk volume, so storage isn't coupled to a single node's filesystem. Config lives in `config/storage.yml` (`minio:`), driven by env:

| Var | Purpose |
|-----|---------|
| `ACTIVE_STORAGE_SERVICE` | `minio` (default in compose) — selects the `minio:` storage service |
| `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` | credentials — **also** the MinIO root user/password |
| `MINIO_BUCKET` | `blog-production` |
| `MINIO_REGION` | `us-east-1` |
| `MINIO_ENDPOINT` | `http://minio:9000` (set directly in compose; internal service name) |

`provision.sh` generates `MINIO_ACCESS_KEY`/`MINIO_SECRET_KEY` on the server with `openssl`. To switch back to local-disk storage, set `ACTIVE_STORAGE_SERVICE=local` (uploads then use the `storage` volume). Back up the `minio` Docker volume — it holds all uploaded images.

### Translator image

Built by a separate workflow, `.github/workflows/translator.yml` — triggers on pushes that touch
`translate-service/**` (or manually via **Run workflow**), and pushes
`ghcr.io/guibsonmoura/blog-translator:latest`. Kept out of the per-push CD because the PyTorch+model
image is heavy and rarely changes. Build it once with `gh workflow run translator.yml`.

### Memory / swap

The translator loads the model (~1.5 GB RAM) and spikes CPU on inference. The VPS has no swap by
default — add a 2 GB swapfile so a spike can't OOM-kill:

```bash
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && \
  sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

`TranslatePostJob` retries on `UnavailableError`, so translations queued before the translator is
healthy complete once it's up. If RAM is too tight, run the translator on a separate host and point
`TRANSLATION_SERVICE_URL` at it — no app changes needed.

## Loopback-only app port (host nginx in front)

The app publishes on the node's `3010`, but it must be reachable **only via `127.0.0.1`** so the
host's nginx can reverse-proxy to it. Docker Swarm has no `host_ip` field in its port model, so the
binding can't be set in `compose.yml` — instead `provision.sh` installs a `DOCKER-USER` firewall
rule that drops non-loopback traffic to the original destination port 3010 (matched pre-DNAT via
conntrack):

```bash
iptables -I DOCKER-USER -p tcp -m conntrack --ctorigdstport 3010 ! -s 127.0.0.0/8 -j DROP
```

Docker resets the `DOCKER-USER` chain on every daemon start, so a systemd oneshot
(`blog-localhost-firewall.service`, `After=docker.service`) re-applies it on boot/restart. Net
effect: `curl 127.0.0.1:3010/up` → 200 on the box; `curl <public-ip>:3010` → refused.

Point nginx at `http://127.0.0.1:3010` (nginx config is managed on the host, outside this repo).

## Make the GHCR packages public

Both `blog` and `blog-translator` are private by default (the VPS pulls them via `guibson`'s cached
GHCR creds). To make them public:

```bash
gh api --method PATCH user/packages/container/blog/visibility -f visibility=public
gh api --method PATCH user/packages/container/blog-translator/visibility -f visibility=public
```

Requires a token with `write:packages` (`gh auth refresh -s read:packages,write:packages`), or flip
each in the web UI: profile → Packages → package → Package settings → Change visibility → Public.

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
