# Assumes Ruby 3.3.x and Rails 8.x for this server-rendered Rails blog.
FROM ruby:3.3-bookworm

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG NODE_MAJOR=22

ENV DEBIAN_FRONTEND=noninteractive \
    GEM_HOME=/usr/local/bundle \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_BIN=/usr/local/bundle/bin \
    PATH=/usr/local/bundle/bin:/workspace/bin:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      git \
      gnupg \
      libpq-dev \
      libvips \
      libyaml-dev \
      pkg-config \
      postgresql-client \
      sudo \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && groupadd --gid "$USER_GID" "$USERNAME" \
    && useradd --uid "$USER_UID" --gid "$USER_GID" -m "$USERNAME" --shell /bin/bash \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" \
    && chmod 0440 "/etc/sudoers.d/$USERNAME" \
    && chown -R "$USERNAME:$USERNAME" /usr/local/bundle \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

USER vscode
