---
name: create-skill
description: Create a new Claude Code skill for this project. Use when asked to add, write, generate, or scaffold a new skill.
---

Guide for creating a new skill in this project. Produces a `.claude/skills/<name>/SKILL.md` that a future agent can follow without re-discovering the project shape.

All paths below are relative to the repo root (`D:\projetos\blog`).

## Project context (already discovered — don't re-explore)

| What | Detail |
|---|---|
| App type | Rails 8.1 web server |
| Dev environment | Docker devcontainer — container name `devcontainer-app-1` |
| App URL | `http://localhost:3000` (port 3000 forwarded from container) |
| Admin panel | `/admin` — login page at `/admin/session/new`, POST credentials to `/admin/session` |
| Run Rails commands | `docker exec devcontainer-app-1 bash -c "cd /workspace && <command>"` |
| Run tests | `docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails test"` |
| Start server (if stopped) | `docker exec -d devcontainer-app-1 bash -c "cd /workspace && bin/rails server -b 0.0.0.0 >> /tmp/rails.log 2>&1"` |
| Check server is up | `curl -sf http://localhost:3000/up` — returns 200 when ready |

## Process

### Step 1 — Identify what the skill covers

Ask (or infer from context): what app, command, or workflow will the skill drive? Give it a short slug: `run-blog`, `deploy`, `seed-db`, etc.

### Step 2 — Run it and interact with the real thing

**Don't paraphrase docs. Execute first.**

For web UI flows, use PowerShell `Invoke-WebRequest` from the host:

```powershell
# Public blog
Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing

# Admin login (get CSRF first, then POST)
$page = Invoke-WebRequest -Uri "http://localhost:3000/admin/session/new" -UseBasicParsing -SessionVariable sess
$csrf = ($page.Content | Select-String 'name="authenticity_token" value="([^"]+)"').Matches[0].Groups[1].Value
$body = "authenticity_token=$([System.Uri]::EscapeDataString($csrf))&email=admin%40example.com&password=password12345"
Invoke-WebRequest -Uri "http://localhost:3000/admin/session" -Method POST -ContentType "application/x-www-form-urlencoded" -Body $body -WebSession $sess -UseBasicParsing -MaximumRedirection 5
```

For Rails/Ruby commands inside the container:

```powershell
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails runner 'puts Post.count'"
```

For web screenshots, use `chromium-cli` (if available) or note the URL + verify via `Invoke-WebRequest`.

**Only document commands you actually ran that worked.**

### Step 3 — Write the SKILL.md

Create `.claude/skills/<name>/SKILL.md` using this template:

```markdown
---
name: <name>
description: <verb-rich description — include "run", "start", "build", "test", "screenshot" so Claude auto-loads it>
---

<One sentence: what this is and how an agent drives it.>

## Prerequisites

<Only system-level things not already in the devcontainer. Usually nothing for this project.>

## Setup

<One-time steps beyond what post-create.sh already does. Usually just env vars if any.>

## Run (agent path)

<The commands an agent runs — background-launch + readiness poll if it's a server.>

## Run (human path)

<If meaningfully different. Usually: open browser to http://localhost:3000.>

## Test

docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails test"

## Gotchas

<Only things you actually hit. Delete this section if empty.>

## Troubleshooting

<Symptom → fix. Only errors you encountered.>
```

### Step 4 — Verify

Follow the SKILL.md cold — a fresh shell, no context from this session. Any step that requires improvisation is a gap; fix it before committing.

## Skill directory rule

Skills live at `.claude/skills/<name>/SKILL.md` at the repo root. The `name:` frontmatter field must match the directory name — that becomes the `/name` slash command.

Optional driver scripts go in the same directory: `.claude/skills/<name>/driver.sh`, `.claude/skills/<name>/smoke.sh`, etc.

## Known gotchas for this project

- **Admin login route** — it's `POST /admin/session`, not `/admin/login`. The login page is `GET /admin/session/new`.
- **CSRF tokens** — must come from a page served by an authenticated session. A token from the login page (pre-auth) won't work for admin-protected POSTs after login.
- **Post creation requires `excerpt`** — the `excerpt` field is required; omitting it returns a 422 with a validation error even though the form shows it as optional-looking.
- **Devcontainer must be running** — `docker ps` should show `devcontainer-app-1` (app), `devcontainer-db-1` (postgres), `devcontainer-minio-1` (minio) all healthy. If not: `docker compose -f .devcontainer/docker-compose.yml up -d`.
- **Rails server inside container** — Puma binds to `0.0.0.0:3000` inside the container; the port is forwarded to the host. All HTTP interaction happens at `http://localhost:3000` from the Windows host.
