# Blog

A personal blog built with Ruby on Rails 8.1. It has a public-facing reading experience and a private admin panel for writing and publishing posts in Markdown. The goal of the project is to provide a fast, minimal, self-hosted blog platform where content is written in Markdown, images are stored in an S3-compatible service (MinIO), and access to the admin area is secured with JWT tokens — no third-party auth provider required.

## Architecture

The application follows a standard Rails MVC structure split into two namespaces:

**Public** — unauthenticated readers browse posts at `/posts`. Only published posts whose `published_at` date is in the past are visible. Posts are paginated (6 per page) and accessed by their slug (`/posts/:slug`). Markdown is rendered server-side using Redcarpet and sanitized before being sent to the browser.

**Admin** — all routes live under `/admin` and require a valid JWT stored in an encrypted HTTP-only cookie. Writers log in at `/admin/session`, manage posts (create / edit / publish / delete) at `/admin/posts`, upload cover images at `/admin/images`, and get a live Markdown preview via `/admin/markdown_preview`.

```
app/
├── controllers/
│   ├── posts_controller.rb          # public index + show
│   └── admin/
│       ├── base_controller.rb       # JWT auth for all admin routes
│       ├── sessions_controller.rb   # login / logout
│       ├── posts_controller.rb      # CRUD
│       ├── images_controller.rb     # cover image upload
│       └── markdown_previews_controller.rb
├── models/
│   ├── post.rb                      # status enum, slug, Active Storage attachment
│   └── user.rb                      # admin flag, Argon2 password
├── services/
│   ├── markdown_renderer.rb         # Redcarpet → sanitized HTML
│   └── json_web_token.rb            # HS256 encode / decode
└── views/
    ├── posts/                       # public pages
    └── admin/                       # editor + session pages
```

**Key technical decisions:**
- JWT stored in an encrypted cookie (not localStorage) — 12-hour expiry, signed with `JWT_SECRET`.
- Passwords hashed with Argon2 (not bcrypt).
- File storage via Active Storage proxied through Rails, backed by MinIO (S3-compatible). Direct S3 URLs are not exposed.
- Tailwind CSS with class-based dark mode; no Node build step — uses `tailwindcss-rails`.
- Hotwire (Turbo + Stimulus) for the live Markdown preview; no full SPA.

## Requirements

- Ruby 3.3.11
- PostgreSQL
- MinIO (or any S3-compatible storage) for file uploads

## Installation

```bash
# 1. Install Ruby gems
bundle install

# 2. Create, migrate, and seed the database
bin/rails db:prepare

# 3. Create the first admin user and a sample post
ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=password12345 bin/rails db:seed
```

## Running the app

```bash
# Development server with Tailwind watcher
bin/dev

# Development server only (no Tailwind rebuild on change)
bin/rails server
```

The app listens on `http://localhost:3000` by default.

## Running tests

```bash
# Full test suite
bin/rails test

# Single test file
bin/rails test test/models/post_test.rb

# Single test by name
bin/rails test test/models/post_test.rb -n test_published_posts_are_listed
```

Tests cover model validations, Markdown sanitization, admin authentication, post publishing states, pagination, and Active Storage behaviour.

## Debugging

```bash
# Open a Rails console (full app context, live DB)
bin/rails console

# Check and apply pending migrations
bin/rails db:migrate:status
bin/rails db:migrate

# Inspect routes
bin/rails routes
bin/rails routes -g admin   # filter to admin namespace

# View logs in real time (development)
tail -f log/development.log

# Rebuild Tailwind if styles are out of sync
bin/rails tailwindcss:build
```

To debug a specific request, add `binding.irb` (or `debugger` with the `debug` gem) inside any controller action or model method and re-trigger the request — the server process will pause and drop into an interactive console.

## Configuration

All secrets and environment-specific values are passed via environment variables.

| Variable | Purpose | Default |
|---|---|---|
| `JWT_SECRET` | Signs admin JWT tokens | `Rails.application.secret_key_base` |
| `MINIO_ENDPOINT` | MinIO server URL | — |
| `MINIO_ACCESS_KEY` | MinIO access key | — |
| `MINIO_SECRET_KEY` | MinIO secret key | — |
| `MINIO_REGION` | Storage region | `us-east-1` |
| `MINIO_BUCKET` | Bucket name | — |
| `ACTIVE_STORAGE_SERVICE` | Storage backend (`minio` or `local`) | `local` in dev |

Example for local MinIO:

```bash
MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_REGION=us-east-1
MINIO_BUCKET=blog-development
ACTIVE_STORAGE_SERVICE=minio
```

## Security scanning (CI)

```bash
bin/brakeman --no-pager      # Rails static security analysis
bin/bundler-audit            # known CVEs in gems
bin/importmap audit          # known CVEs in JS packages
bin/rubocop -f github        # code style (Omakase Rails)
```
