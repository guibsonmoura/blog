# Architecture

## Overview

A server-rendered Rails 8.1 blog. The backend produces HTML directly — no API, no SPA. Hotwire (Turbo + Stimulus) handles the few dynamic interactions without a JavaScript framework.

## Stack

| Layer | Choice |
|-------|--------|
| Language | Ruby 3.3.11 |
| Framework | Rails 8.1.3 |
| Database | PostgreSQL |
| CSS | Tailwind CSS v4 via `tailwindcss-rails` |
| Assets | Propshaft |
| JS | Hotwire — Turbo + Stimulus via importmap |
| Storage | Active Storage → MinIO (S3-compatible) |
| Auth | JWT stored in encrypted HTTP-only cookie |
| Passwords | Argon2 |
| Markdown | Redcarpet → sanitized HTML |

## Structure

```
app/
├── controllers/
│   ├── application_controller.rb   # locale + reader session
│   ├── posts_controller.rb         # public index + show
│   ├── comments_controller.rb      # anonymous comment create
│   ├── reactions_controller.rb     # emoji reaction toggle
│   ├── locales_controller.rb       # EN/PT cookie toggle
│   └── admin/
│       ├── base_controller.rb      # JWT auth guard
│       ├── sessions_controller.rb  # login / logout
│       ├── posts_controller.rb     # CRUD
│       ├── images_controller.rb    # inline image upload
│       ├── comments_controller.rb  # comment delete
│       └── markdown_previews_controller.rb
├── models/
│   ├── post.rb       # markdown parsing, slug, status enum
│   ├── comment.rb    # belongs_to post
│   ├── reaction.rb   # belongs_to post, session-based
│   └── user.rb       # admin flag, Argon2
├── services/
│   ├── markdown_renderer.rb   # Redcarpet + sanitize
│   └── json_web_token.rb      # HS256 encode/decode
└── views/
    ├── posts/         # public pages + partials
    └── admin/         # editor + session pages
```

## Request flow

**Public reader:**
1. `GET /` → `PostsController#index` → paginated `Post.visible` (published + `published_at <= now`)
2. `GET /posts/:slug` → `PostsController#show` → renders markdown body + reactions + comments
3. `POST /posts/:slug/reactions` → `ReactionsController#create` → toggle by session UUID
4. `POST /posts/:slug/comments` → `CommentsController#create` → anonymous comment

**Admin writer:**
1. `GET /superadmin/login` → login form (no link to this from public pages)
2. `POST /superadmin/login` → JWT encoded, stored in encrypted HTTP-only cookie (`admin_token`)
3. All `/admin/*` routes → `Admin::BaseController#require_admin!` decodes JWT, checks `user.admin?`
4. Post form submits only `body_markdown`, `status`, `published_at` — title/excerpt/slug extracted from markdown

## Data model

```
users         posts             comments          reactions
─────────     ──────────────    ────────────      ─────────────
id            id                id                id
email         user_id (FK)      post_id (FK)      post_id (FK)
name          title             author_name       reaction_type
admin         slug (unique)     author_email      session_id
password_     excerpt           body              created_at
 digest       body_markdown     created_at
              status (enum)     updated_at
              published_at
              created_at
```

## Key design decisions

- **No reader accounts.** Reactions are tracked by a UUID session cookie (`reader_id`) set on first visit. Comments are anonymous (name + optional email).
- **Markdown as source of truth.** The post form accepts only a markdown textarea. Title, excerpt, and slug are parsed from the content by `Post#extract_from_markdown` before validation.
- **Active Storage proxied.** Images are served through Rails (`resolve_model_to_route: :rails_storage_proxy`), not directly from MinIO. MinIO buckets stay private.
- **JWT in encrypted cookie.** Token is HTTP-only, `SameSite: Lax`, `Secure` in production, 12-hour expiry. Falls back to `secret_key_base` if `JWT_SECRET` env var is not set.
