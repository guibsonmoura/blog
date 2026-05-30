# Specification: Set Up a `.devcontainer` for the Rails Blog Project

This document specifies how an AI assistant should generate a complete `.devcontainer` configuration for the blog application described in `blog-project-prompt.md`. The goal is a reproducible, ready-to-code development environment that any contributor can open in VS Code (or any Dev Containers–compatible editor) and have everything working with no manual setup.

## Target stack (must match the blog project)

The devcontainer must support all of the following from the blog project:

- **Ruby on Rails** (server-rendered MVC, serving HTML with Tailwind CSS).
- **PostgreSQL** as the database.
- **MinIO** (S3-compatible) for image storage via Active Storage.
- **Tailwind CSS** build tooling (Node.js required for the asset pipeline / `tailwindcss-rails` or `cssbundling-rails`).
- **JWT-based authentication** (no extra services needed, but ensure required gems build).
- **Markdown rendering** gem (e.g., Redcarpet/Commonmarker — ensure native extensions compile).

## Required deliverables

The AI must produce these files inside a `.devcontainer/` directory:

1. `.devcontainer/devcontainer.json`
2. `.devcontainer/docker-compose.yml`
3. `.devcontainer/Dockerfile`
4. A short `README` section (or comments) explaining how to open and use it.

## `devcontainer.json` requirements

- Reference the `docker-compose.yml` and set the Rails app as the primary service (`service`) and `workspaceFolder` to `/workspace`.
- Install useful VS Code extensions: Ruby/Rails language support (e.g., Shopify Ruby LSP), Tailwind CSS IntelliSense, and an EditorConfig extension.
- Forward the relevant ports:
  - `3000` — Rails server.
  - `5432` — PostgreSQL.
  - `9000` — MinIO API.
  - `9001` — MinIO console.
- Set a `postCreateCommand` that runs `bundle install`, installs JS dependencies (`yarn install` or `npm install` if used by Tailwind tooling), and prepares the database (`bin/rails db:prepare`).
- Run as a non-root `vscode` user.

## `docker-compose.yml` requirements

Define these services:

- **app** — built from the local `Dockerfile`; mounts the project into `/workspace`; depends on `db` and `minio`; keeps the container running for development (e.g., `sleep infinity`); receives environment variables for the database and MinIO connections.
- **db** — official `postgres` image (pin a recent stable version); persistent named volume for data; set `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` via environment.
- **minio** — official `minio/minio` image; expose ports `9000` (API) and `9001` (console); set `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`; persistent named volume for object data; start with the console enabled (`server /data --console-address ":9001"`).
- **createbuckets** (optional helper) — a short-lived `minio/mc` container that waits for MinIO, then creates the bucket the app expects (e.g., `blog-images`) and sets an appropriate access policy, so Active Storage has its bucket on first run.

Use a shared network and named volumes for `db` and `minio` so data persists across rebuilds.

## `Dockerfile` requirements

- Base on an official Ruby image matching the Rails version the project targets (state the assumed version).
- Install system dependencies needed to build common gems and run the toolchain: `build-essential`, `libpq-dev` (PostgreSQL client/headers), `git`, `curl`, and anything required by the chosen Markdown gem's native extension.
- Install **Node.js** (and `yarn` if used) for Tailwind CSS asset building.
- Create the non-root `vscode` user.
- Keep the image lean; do not bake application source into the image (it is mounted as a volume in development).

## Environment variables to wire up

Provide these so the app connects to the services out of the box (the AI should set them in `docker-compose.yml` / `devcontainer.json` and reference them from Rails config):

- `DATABASE_URL` or discrete `POSTGRES_*` values pointing at the `db` service host.
- `MINIO_ENDPOINT` (e.g., `http://minio:9000`), `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET`, and `MINIO_REGION` for the Active Storage S3 adapter.
- A development `SECRET_KEY_BASE` and a separate signing secret for **JWT** (e.g., `JWT_SECRET`).

Document that real secrets must not be committed; the devcontainer values are for local development only.

## Acceptance criteria

The setup is correct when:

1. Opening the folder in a Dev Containers–compatible editor builds without errors.
2. After `postCreateCommand`, `bin/rails server` starts and the blog is reachable at `localhost:3000`.
3. PostgreSQL is reachable from the app and migrations run cleanly.
4. MinIO is reachable, the expected bucket exists, and Active Storage can upload/serve an image.
5. Tailwind CSS compiles and the light/dark theme renders correctly.
6. The Markdown gem's native extension compiled successfully.

## What I'd like from the AI

1. Generate all four deliverables with complete, working contents (not placeholders).
2. State the assumed Ruby and Rails versions explicitly.
3. Explain any non-obvious choices briefly (e.g., why MinIO uses two ports, how the bucket bootstrap works).
4. Note any Rails config snippets (e.g., `config/storage.yml` for the MinIO/S3 adapter, database config) that must change to match these services.
5. Keep everything aligned with the stack in `blog-project-prompt.md` — do not introduce a different database, storage backend, or auth approach.
