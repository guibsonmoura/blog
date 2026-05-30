#!/usr/bin/env bash
set -euo pipefail

cd /workspace

if [ -f Gemfile ]; then
  bundle check || bundle install
else
  echo "No Gemfile found; skipping bundle install until the Rails app is scaffolded."
fi

if [ -f package.json ]; then
  if [ -f yarn.lock ]; then
    yarn install
  elif [ -f pnpm-lock.yaml ]; then
    pnpm install
  else
    npm install
  fi
else
  echo "No package.json found; skipping JavaScript dependency install."
fi

if [ -x bin/rails ]; then
  bin/rails db:prepare
else
  echo "bin/rails not found; skipping database prepare until the Rails app is scaffolded."
fi
