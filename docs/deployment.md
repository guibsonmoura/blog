# Deployment (CI/CD)

## Pipelines

| Workflow | File | Trigger | What it does |
|----------|------|---------|--------------|
| **CI** | `.github/workflows/ci.yml` | PRs + push to `master` | brakeman, bundler-audit, importmap audit, rubocop, full test suite |
| **CD** | `.github/workflows/cd.yml` | push to `master` + manual (`workflow_dispatch`) | Build → release → push to GHCR → SSH deploy |

## CD flow

On every push to `master` (or a manual run), the CD pipeline:

1. **Computes a version** — CalVer `vYYYY.MM.DD-<run_number>` (always unique, ordered, no manual bumping).
2. **Builds the production image** from `Dockerfile` and tags it `:latest` **and** `:<version>`.
3. **Pushes both tags to GHCR** → `ghcr.io/guibsonmoura/blog`.
4. **Creates a GitHub Release + git tag** for the version (auto-generated release notes).
5. **Deploys over SSH** — connects to the server, logs into GHCR, `docker compose pull app`, `docker compose up -d app`, prunes old images.

```
push to master
   │
   ├─ release job ─ build ─ push ghcr.io/guibsonmoura/blog:{latest,vX} ─ create GitHub Release
   │
   └─ deploy job (needs release) ─ ssh ─ docker compose pull app ─ up -d app
```

## Required GitHub secrets

Set under **Settings → Secrets and variables → Actions**:

| Secret | Needed by | Purpose |
|--------|-----------|---------|
| `SSH_HOST` | deploy | Server IP / hostname |
| `SSH_USER` | deploy | SSH user (must be in the `docker` group) |
| `SSH_KEY` | deploy | Private key (PEM) for that user |
| `SSH_PORT` | deploy | Optional — defaults to 22 |
| `GHCR_TOKEN` | deploy | PAT with `read:packages` so the **server** can pull the image (only if the package is private — see below) |

The **build/push/release** job needs **no extra secrets** — it uses the built-in `GITHUB_TOKEN`. So releases and GHCR images work immediately; only the `deploy` job waits on the SSH secrets.

> The `deploy` job will **fail until the SSH secrets exist** — that's expected, not a bug. Until then, every push still produces a release + a pushed image you can deploy manually.

## GHCR image visibility

The server has to pull `ghcr.io/guibsonmoura/blog:latest`. Two options:

- **Public package (simplest):** GitHub → repo → Packages → the `blog` package → Package settings → change visibility to **Public**. Then the server needs no login and you can drop `GHCR_TOKEN`.
- **Private package:** create a PAT with `read:packages`, store it as `GHCR_TOKEN`; the deploy step runs `docker login ghcr.io` with it on the server.

## One-time server setup

```bash
# 1. Install Docker Engine + compose plugin (Ubuntu example)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"   # log out/in after this

# 2. Lay down the deploy files
sudo mkdir -p /opt/blog && sudo chown "$USER" /opt/blog
cd /opt/blog
# copy deploy/compose.yml from this repo to /opt/blog/compose.yml
# copy deploy/.env.example to /opt/blog/.env and fill in real values
cp /path/to/repo/deploy/compose.yml ./compose.yml
cp /path/to/repo/deploy/.env.example ./.env && nano .env

# 3. Auth to GHCR (skip if the package is public)
echo "<GHCR_PAT>" | docker login ghcr.io -u guibsonmoura --password-stdin

# 4. First boot
docker compose up -d
```

After this, every push to `master` auto-deploys.

## Rolling back

Deploy a specific previous version instead of `latest`:

```bash
cd /opt/blog
docker pull ghcr.io/guibsonmoura/blog:v2026.05.30-42
# point compose at that tag (edit image: tag) or:
docker compose down app
docker run -d --env-file .env -p 80:80 --network blog_blog \
  ghcr.io/guibsonmoura/blog:v2026.05.30-42
```

Available versions are listed under the repo's **Releases** and **Packages** tabs.

## Database migrations

The image's `bin/docker-entrypoint` runs `db:prepare` on boot, so migrations apply automatically when the new container starts. No manual migration step is needed in the pipeline.
