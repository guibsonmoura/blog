# Blog

Ruby on Rails 8.1.3 blog application with server-rendered public pages, a JWT-protected admin panel, Argon2 password hashing, Tailwind styling, Markdown rendering, and Active Storage support for MinIO.

## Setup

Install dependencies:

```bash
bundle install
```

Prepare the PostgreSQL database:

```bash
bin/rails db:prepare
```

Seed the first admin user and a sample post:

```bash
ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=password12345 bin/rails db:seed
```

Run the app:

```bash
bin/dev
```

Use `bin/rails server` if you do not need the Tailwind watcher.

Run tests:

```bash
bin/rails test
```

Build Tailwind assets:

```bash
bin/rails tailwindcss:build
```

## Configuration

Production uses the `minio` Active Storage service by default. Configure it with environment variables:

```bash
MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_REGION=us-east-1
MINIO_BUCKET=blog-production
ACTIVE_STORAGE_SERVICE=minio
```

JWT admin tokens are signed with `JWT_SECRET`, falling back to `Rails.application.secret_key_base`, and stored in encrypted, HTTP-only cookies with a 12-hour expiry.

User passwords are hashed with Argon2 in the `password_digest` column. Plaintext passwords are never stored.
