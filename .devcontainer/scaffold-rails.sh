#!/usr/bin/env bash
set -euo pipefail

cd /workspace

gem install rails -v '~> 8.0' --no-document
ruby -S rails new . \
  --database=postgresql \
  --css=tailwind \
  --skip-jbuilder \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-system-test \
  --skip-devcontainer \
  --skip-git \
  --force
