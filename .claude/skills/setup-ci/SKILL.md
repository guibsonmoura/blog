---
name: setup-ci
description: Set up, fix, run, and verify the GitHub Actions CI pipeline for this Rails project. Use when asked to configure CI, debug a failing workflow, run the CI checks locally, or make sure CI triggers on the right branch.
---

Drives the project's GitHub Actions CI (`.github/workflows/ci.yml`) — four parallel jobs that mirror the local quality gates. An agent uses this to verify CI is wired correctly, run the same checks locally before pushing, and fix the common misconfigurations.

## What CI runs

`.github/workflows/ci.yml` defines four parallel jobs, all on `ubuntu-latest` with `ruby/setup-ruby` + `bundler-cache`:

| Job | Command | Purpose |
|-----|---------|---------|
| `scan_ruby` | `bin/brakeman --no-pager` then `bin/bundler-audit` | Rails static security scan + gem CVE audit |
| `scan_js` | `bin/importmap audit` | JS dependency CVE audit |
| `lint` | `bin/rubocop -f github` | Omakase Ruby style (with RuboCop cache) |
| `test` | `bin/rails db:test:prepare test` | Full test suite against a `postgres` service |

The `test` job boots a `postgres` service container and connects via `DATABASE_URL=postgres://postgres:postgres@localhost:5432`.

## Triggers — CRITICAL gotcha

The workflow triggers on:

```yaml
on:
  pull_request:
  push:
    branches: [ master ]
```

**This repo's default branch is `master`, not `main`.** The upstream Rails template ships `branches: [ main ]`, which means pushes to `master` silently never run CI. When setting up CI here, always confirm the push branch matches the default branch:

```bash
git -C . symbolic-ref refs/remotes/origin/HEAD   # shows the real default branch
gh repo view --json defaultBranchRef -q .defaultBranchRef.name
```

If they don't match, fix the `branches:` list in `ci.yml`.

## Run the CI checks locally (agent path)

Run the exact same gates before pushing, inside the devcontainer:

```bash
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/brakeman --no-pager"
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/bundler-audit"
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/importmap audit"
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rubocop -f github"
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails db:test:prepare test"
```

All five passing locally ≈ green CI.

## Verify CI on GitHub

```bash
gh run list --limit 5                 # recent workflow runs + status
gh run watch                          # follow the latest run live
gh run view --log-failed              # logs for failed steps only
```

A push to `master` or any PR should appear in `gh run list` within ~10s. If nothing appears after a push to the default branch, the `branches:` trigger is wrong (see gotcha above).

## Add a new CI job

Append under `jobs:` in `ci.yml`, mirroring the existing shape: `runs-on: ubuntu-latest`, `actions/checkout@v6`, `ruby/setup-ruby@v1` with `bundler-cache: true`, then the command. Add a `services:` block only if the job needs Postgres/MinIO.

## Secrets

The `test` job has commented-out `RAILS_MASTER_KEY` / `REDIS_URL`. If a job needs a secret, add it in the repo settings and reference it as `${{ secrets.NAME }}`:

```bash
gh secret set RAILS_MASTER_KEY    # paste value when prompted
gh secret list
```

## Gotchas

- **`main` vs `master`** — the #1 reason "CI doesn't run." The default branch here is `master`.
- **`actions/checkout@v6`** is pinned project-wide; keep new jobs on the same major.
- **Brakeman/bundler-audit/importmap/rubocop are run via `bin/`** binstubs — they exist in the repo, no `bundle exec` prefix needed.
- **The test job needs `libpq-dev libvips`** installed via apt before `setup-ruby` (Active Storage variants + pg). Replicate that `Install packages` step in any new job that runs the app.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Push to master shows no CI run | `branches:` list doesn't include `master` — fix `ci.yml` |
| `test` job fails on DB connection | Confirm the `postgres` service block + `DATABASE_URL` env are present |
| `lint` fails only in CI | Run `bin/rubocop -f github` locally in the container; fix or `bin/rubocop -a` |
| `scan_ruby` fails | `bin/brakeman --no-pager` locally; address or add to `config/brakeman.ignore` |
