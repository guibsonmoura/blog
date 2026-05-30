# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

Ruby on Rails 8.1.3, PostgreSQL, Tailwind CSS (via `tailwindcss-rails`), Hotwire (Turbo + Stimulus), Propshaft, Active Storage with MinIO (S3-compatible), JWT auth, Argon2 password hashing, Redcarpet markdown rendering.

## Commands

```bash
bundle install                                          # install gems
bin/rails db:prepare                                    # create + migrate + seed DB
ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=password12345 bin/rails db:seed  # seed admin user
bin/dev                                                 # dev server + Tailwind watcher
bin/rails server                                        # dev server only
bin/rails test                                          # full test suite
bin/rails test test/models/post_test.rb                 # single test file
bin/rails tailwindcss:build                             # compile Tailwind once
```

CI also runs: `bin/brakeman --no-pager`, `bin/bundler-audit`, `bin/importmap audit`, `bin/rubocop -f github`.

## Architecture

Public blog and admin panel are separate Rails namespaces sharing models.

**Public** (`PostsController`): index (paginated, 6 per page) and show (by slug). Only `published` posts with `published_at <= now` are visible.

**Admin** (`Admin::` namespace, all routes under `/admin`):
- `Admin::SessionsController` — JWT login/logout; token stored in encrypted HTTP-only cookie (`admin_token`), 12-hour expiry.
- `Admin::BaseController` — `require_admin!` before filter on all admin controllers; decodes JWT via `JsonWebToken` service.
- `Admin::PostsController` — full CRUD; sees drafts too.
- `Admin::ImagesController` — cover image upload (PNG/JPG/WebP/GIF, max 5 MB) via Active Storage.
- `Admin::MarkdownPreviewsController` — live Markdown-to-HTML preview endpoint.

**Key models:**
- `Post`: `status` enum (`draft`/`published`), `slug` (auto-generated from title, used in `to_param`), `body_markdown`, `cover_image` (Active Storage attachment), `published_at` (auto-set on publish).
- `User`: `admin` boolean flag, Argon2 `password_digest`.

**Services:**
- `MarkdownRenderer` (`app/services/markdown_renderer.rb`): Redcarpet render → ActionView HTML sanitizer. Fenced code, tables, strikethrough, autolink enabled. Links get `rel="nofollow noopener"`.
- `JsonWebToken` (`app/services/json_web_token.rb`): HS256, signs with `JWT_SECRET` env var (falls back to `secret_key_base`).

**Storage:** Active Storage proxied through Rails (not direct S3 URLs) — configured in `config/application.rb`. MinIO credentials via `MINIO_*` env vars; service name via `ACTIVE_STORAGE_SERVICE`.

## Conventions

- Tailwind classes support light and dark themes via class-based dark mode.
- Commit messages follow Conventional Commits: `feat:`, `fix:`, `refactor:`, etc.
- PRs should include screenshots for UI changes and call out JWT, Markdown sanitization, or MinIO credential changes explicitly.
- Strong parameters enforced in all admin controllers; all Markdown HTML is sanitized before render.
