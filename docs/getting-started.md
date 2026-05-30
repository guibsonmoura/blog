# Getting Started

## Option A — Dev Container (recommended)

Requires Docker and the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) VS Code extension.

1. Open the repo folder in VS Code.
2. When prompted, choose **Reopen in Container** (or run `Dev Containers: Reopen in Container` from the command palette).
3. The container builds and `post-create.sh` runs automatically — it installs gems and runs `bin/rails db:prepare`.
4. Start the server inside the container terminal:
   ```bash
   bin/dev
   ```
5. Open [http://localhost:3000](http://localhost:3000).

Forwarded ports:

| Port | Service |
|------|---------|
| 3000 | Rails server |
| 5432 | PostgreSQL |
| 9000 | MinIO S3 API |
| 9001 | MinIO console (`minioadmin` / `minioadmin123`) |

All environment variables (database, MinIO, JWT secret) are pre-configured in `.devcontainer/docker-compose.yml`. No `.env` file needed for local development.

## Option B — Local setup

Requirements: Ruby 3.3.11, PostgreSQL, MinIO.

```bash
bundle install
bin/rails db:prepare
bin/dev          # starts Rails + Tailwind watcher
```

Set these environment variables before starting:

```bash
MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123
MINIO_REGION=us-east-1
MINIO_BUCKET=blog-development
ACTIVE_STORAGE_SERVICE=minio
JWT_SECRET=your-secret-here          # optional, falls back to secret_key_base
```

## Seed the first admin user

```bash
ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=password12345 bin/rails db:seed
```

Then sign in at [http://localhost:3000/superadmin/login](http://localhost:3000/superadmin/login).

## Useful commands

```bash
bin/rails test                            # run all tests
bin/rails test test/models/post_test.rb  # single file
bin/rails console                         # Rails console (live DB)
bin/rails routes                          # list all routes
bin/rails routes -g admin                 # filter to admin namespace
bin/rails tailwindcss:build               # rebuild CSS (if watcher isn't running)
bin/rails db:migrate                      # apply pending migrations
```

## CI checks (run locally before pushing)

```bash
bin/brakeman --no-pager    # security scan
bin/bundler-audit          # gem CVEs
bin/importmap audit        # JS CVEs
bin/rubocop -f github      # code style
```
