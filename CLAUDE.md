# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
Keep this file around 200 lines — enough to be useful, not so long it becomes noise.

## Stack

Ruby on Rails 8.1.3, PostgreSQL, Tailwind CSS (via `tailwindcss-rails`), Hotwire (Turbo + Stimulus),
Propshaft, Active Storage with MinIO (S3-compatible), JWT auth, Argon2 password hashing, Redcarpet
markdown rendering.

## Commands

```bash
bundle install                                                              # install gems
bin/rails db:prepare                                                       # create + migrate + seed DB
ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=password12345 bin/rails db:seed  # seed admin user
bin/dev                                                                    # dev server + Tailwind watcher
bin/rails server                                                           # dev server only
bin/rails test                                                             # full test suite
bin/rails test test/models/post_test.rb                                    # single test file
bin/rails tailwindcss:build                                                # compile Tailwind once
```

CI also runs: `bin/brakeman --no-pager`, `bin/bundler-audit`, `bin/importmap audit`, `bin/rubocop -f github`.

## Architecture

Public blog and admin panel are separate Rails namespaces sharing models.

**Public** (`PostsController`): index (paginated, 6 per page) and show (by slug). Only `published`
posts with `published_at <= now` are visible.

**Admin** (`Admin::` namespace, all routes under `/admin`):
- `Admin::SessionsController` — JWT login/logout; token stored in encrypted HTTP-only cookie (`admin_token`), 12-hour expiry.
- `Admin::BaseController` — `require_admin!` before filter on all admin controllers; decodes JWT via `JsonWebToken` service.
- `Admin::PostsController` — full CRUD; sees drafts too.
- `Admin::ImagesController` — cover image upload (PNG/JPG/WebP/GIF, max 5 MB) via Active Storage.
- `Admin::MarkdownPreviewsController` — live Markdown-to-HTML preview endpoint.

**Key models:**
- `Post`: `status` enum (`draft`/`published`), `slug` (auto-generated from title, used in `to_param`),
  `body_markdown`, `cover_image` (Active Storage attachment), `published_at` (auto-set on publish).
- `User`: `admin` boolean flag, Argon2 `password_digest`.

**Services:**
- `MarkdownRenderer` (`app/services/markdown_renderer.rb`): Redcarpet render → ActionView HTML sanitizer.
  Fenced code, tables, strikethrough, autolink enabled. Links get `rel="nofollow noopener"`.
- `JsonWebToken` (`app/services/json_web_token.rb`): HS256, signs with `JWT_SECRET` env var
  (falls back to `secret_key_base`).

**Storage:** Active Storage proxied through Rails (not direct S3 URLs) — configured in
`config/application.rb`. MinIO credentials via `MINIO_*` env vars; service name via `ACTIVE_STORAGE_SERVICE`.

## Dev Container

This project runs inside a **VS Code Dev Container** (`.devcontainer/`). The container stack is:

| Service | Container | Port |
|---|---|---|
| Rails app | `devcontainer-app-1` | 3000 |
| PostgreSQL 17 | `devcontainer-db-1` | 5432 (internal) |
| MinIO (S3) | `devcontainer-minio-1` | 9000 API / 9001 console |

**Starting the stack:**

```bash
# From repo root — starts all three services
docker compose -f .devcontainer/docker-compose.yml up -d
```

**Running commands inside the container:**

```bash
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails db:prepare"
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails test"
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails tailwindcss:build"
```

**Starting the Rails server (if not already running):**

```bash
docker exec -d devcontainer-app-1 bash -c "cd /workspace && bin/rails server -b 0.0.0.0 >> /tmp/rails.log 2>&1"
# Verify: curl -sf http://localhost:3000/up
```

The `post-create.sh` script (`.devcontainer/post-create.sh`) runs automatically on container creation and handles `bundle install` + `db:prepare`.

All env vars (database credentials, MinIO keys, JWT secret) are pre-set in `.devcontainer/docker-compose.yml` for local development — no `.env` file needed.

## Git Worktrees

Worktrees let you check out multiple branches simultaneously in separate directories. All worktrees
share the same `.git` — commits, branches, and history are shared, but files on disk are independent.

Convention for this project: create worktrees as siblings of the main repo directory, under a
`blog-worktrees/` folder, named after the branch.

```bash
# Create a worktree for a new feature branch
git worktree add ../blog-worktrees/feat/my-feature -b feat/my-feature

# List active worktrees
git worktree list

# Run the app from a worktree on a different port (so master stays on 3000)
cd ../blog-worktrees/feat/my-feature
bundle install
bin/rails server -p 3001

# Remove a worktree after the branch is merged
git worktree remove ../blog-worktrees/feat/my-feature

# Clean up stale references (after manually deleting a worktree directory)
git worktree prune
```

Rules:
- The same branch cannot be checked out in two worktrees at the same time — Git will refuse it.
- Each worktree maintains its own `tmp/` and `log/` — Rails handles this automatically.
- Run tests inside the worktree directory — they run against that worktree's code and DB migrations.

## Conventions

- Tailwind classes support light and dark themes via class-based dark mode.
- Commit messages follow Conventional Commits: `feat:`, `fix:`, `refactor:`, etc.
- PRs should include screenshots for UI changes and call out JWT, Markdown sanitization, or MinIO
  credential changes explicitly.
- Strong parameters enforced in all admin controllers; all Markdown HTML is sanitized before render.
