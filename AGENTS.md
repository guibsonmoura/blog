# Repository Guidelines

## Project Structure & Module Organization

This repository currently contains planning material for a Ruby on Rails blog application. The main requirements live in `specs/about.md`.

When implementation begins, follow standard Rails MVC layout:

- `app/models` for domain objects such as `Post` and `Admin` or `User`.
- `app/controllers` for public blog controllers; use `app/controllers/admin` for authenticated admin CRUD.
- `app/views` for server-rendered ERB views and shared partials, including Markdown rendering and editor UI.
- `app/assets`, `app/javascript`, and Tailwind config for styling and theme behavior.
- `config/storage.yml` for MinIO-backed Active Storage configuration.
- `db/migrate` for PostgreSQL schema changes.
- `test` or `spec` for automated tests, depending on the test framework adopted.

## Build, Test, and Development Commands

No Rails app scripts exist yet. After scaffolding the Rails application, prefer conventional Rails commands:

- `bundle install`: install Ruby gem dependencies.
- `bin/rails db:prepare`: create, migrate, and seed the PostgreSQL database.
- `bin/rails server`: run the local Rails server.
- `bin/rails test`: run the default Rails test suite, unless RSpec is added.
- `bin/rails tailwindcss:build`: build Tailwind assets if using `tailwindcss-rails`.

Document any new commands in the README when they are introduced.

## Coding Style & Naming Conventions

Use idiomatic Rails and Ruby style: two-space indentation, `snake_case` files and methods, `PascalCase` classes/modules, and RESTful controller actions where practical. Keep public blog code separate from admin code through Rails namespaces such as `Admin::PostsController`.

Keep styling minimalist and content-focused. Tailwind classes should support both light and dark themes using class-based dark mode.

## Testing Guidelines

Add tests alongside each feature. Cover model validations, Markdown sanitization, admin authentication, post publishing states, pagination, and Active Storage behavior. Use descriptive test names such as `test_published_posts_are_listed` or RSpec examples like `it "sanitizes rendered markdown"`.

## Commit & Pull Request Guidelines

This directory is not currently a Git repository, so no local commit history is available. Use clear, imperative commit messages, preferably Conventional Commits, such as `feat: add admin post editor` or `fix: sanitize markdown output`.

Pull requests should include a short summary, linked issue or spec section, test results, screenshots for UI changes, and notes about security-sensitive changes such as JWT handling, Markdown sanitization, or MinIO credentials.

## Security & Configuration Tips

Never commit secrets, JWT signing keys, MinIO credentials, or database passwords. Use Rails credentials or environment variables. Sanitize all Markdown-derived HTML before rendering, enforce strong parameters, and protect all admin routes with explicit authentication checks.
