# Git Workflow

## Branch convention

| Branch | Purpose |
|--------|---------|
| `master` | Stable, production-ready |
| `feat/*` | New features |
| `fix/*` | Bug fixes |

All feature work happens in a dedicated branch, opened as a PR, merged via GitHub, and then cleaned up.

## Worktrees

This project uses Git worktrees to work on multiple branches simultaneously without stashing or switching. All worktrees live as siblings of the main repo under `blog-worktrees/`.

```bash
# Create a worktree for a new branch
git worktree add ../blog-worktrees/feat/my-feature -b feat/my-feature

# List active worktrees
git worktree list

# Run the app from a worktree on a different port
cd ../blog-worktrees/feat/my-feature
bin/rails server -p 3001          # inside the dev container

# Remove when the branch is merged
git worktree remove ../blog-worktrees/feat/my-feature
git branch -d feat/my-feature

# Clean up stale references
git worktree prune
```

Rules:
- The same branch cannot be checked out in two worktrees simultaneously — Git refuses it.
- Run tests from inside the worktree directory so they pick up that branch's migrations.
- Each worktree has its own `tmp/` and `log/` — Rails handles this automatically.

## Commit messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add emoji reactions to post show page
fix: clear published_at when post reverts to draft
docs: add git workflow guide
refactor: extract markdown parsing into service object
test: add unit tests for extract_from_markdown callback
```

## Pull requests

PRs should include:
- A short summary of what changed and why
- Screenshots for any UI changes
- Explicit callout if the PR touches JWT handling, Markdown sanitization, or MinIO credentials
- `bin/rails test` passing in the dev container

## Previewing a feature branch

To preview a feature branch without switching the main dev container:

```bash
# On the Windows host — start a temporary preview container
docker run -d --name blog-preview \
  --network devcontainer_blog-dev \
  -p 3001:3001 \
  -v "D:/projetos/blog-worktrees/feat/my-feature:/workspace:cached" \
  -v devcontainer_bundle-cache:/usr/local/bundle \
  -e RAILS_ENV=development \
  -e POSTGRES_HOST=db \
  -e POSTGRES_USER=blog \
  -e POSTGRES_PASSWORD=blog_password \
  -e POSTGRES_DB=blog_development \
  -e MINIO_ENDPOINT=http://minio:9000 \
  -e MINIO_ACCESS_KEY=minioadmin \
  -e MINIO_SECRET_KEY=minioadmin123 \
  -e MINIO_BUCKET=blog-images \
  -e MINIO_REGION=us-east-1 \
  -e ACTIVE_STORAGE_SERVICE=minio \
  -e SECRET_KEY_BASE=<same-as-devcontainer> \
  -e JWT_SECRET=devcontainer-jwt-secret-change-outside-local-dev \
  devcontainer-app sleep infinity

docker exec blog-preview bash -c "cd /workspace && bin/rails db:migrate && bin/rails tailwindcss:build && bin/rails server -b 0.0.0.0 -p 3001 &"
```

Open [http://localhost:3001](http://localhost:3001). Clean up when done:

```bash
docker stop blog-preview && docker rm blog-preview
```
