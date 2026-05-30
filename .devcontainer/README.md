# Dev Container

This setup assumes Ruby 3.3.x, Rails 8.x, PostgreSQL 17, Tailwind CSS tooling through Node.js 22, and MinIO for Active Storage in development.

Open this repository in VS Code and choose **Dev Containers: Reopen in Container**. The `app` service mounts the project at `/workspace`, runs as the non-root `vscode` user, and stays alive with `sleep infinity` so you can run Rails commands manually. On first create, `.devcontainer/post-create.sh` installs Ruby and JavaScript dependencies and runs `bin/rails db:prepare` when a Rails app is present.

Forwarded ports:

- `3000`: Rails server.
- `5432`: PostgreSQL, reachable from Rails as host `db`.
- `9000`: MinIO S3 API.
- `9001`: MinIO web console. Sign in with `minioadmin` / `minioadmin123`.

The `createbuckets` helper waits for MinIO, creates the `blog-images` bucket, and leaves it private. Use Rails proxy URLs for browser-facing image delivery, or add a separate public endpoint strategy before enabling direct uploads.

Example Rails configuration:

```yaml
# config/database.yml
development:
  url: <%= ENV.fetch("DATABASE_URL") %>
```

```yaml
# config/storage.yml
minio:
  service: S3
  access_key_id: <%= ENV.fetch("MINIO_ACCESS_KEY") %>
  secret_access_key: <%= ENV.fetch("MINIO_SECRET_KEY") %>
  region: <%= ENV.fetch("MINIO_REGION", "us-east-1") %>
  bucket: <%= ENV.fetch("MINIO_BUCKET") %>
  endpoint: <%= ENV.fetch("MINIO_ENDPOINT") %>
  force_path_style: true
```

Set `config.active_storage.service = :minio` in development. The included secrets are local-only defaults; use Rails credentials or environment variables for real deployments.
