# Build a Blog Application in Ruby on Rails with an Admin Panel

I'm building a blog in Ruby on Rails and need help implementing it. The goal is a **clean, minimalist blog** with an admin panel for managing posts. Here are the requirements.

## Architecture

- **Pattern:** Standard Rails MVC.
- **Rendering:** Server-side. The Rails backend serves the HTML pages directly (server-rendered views), no separate frontend SPA.
- **Styling:** Tailwind CSS, kept as minimalist as possible — generous whitespace, simple typography, minimal color, no visual clutter. Support both **light and dark themes** (Tailwind dark mode, class strategy).

## Public-facing blog

- A homepage listing published posts (title, excerpt, author, publish date, cover image).
- Individual post pages that render the post's **Markdown content** as sanitized HTML.
- Pagination for the post list.
- Minimalist design throughout — content first, very little chrome.
- **Light and dark theme** with a toggle. Use Tailwind's dark mode (class strategy), provide a visible toggle button, and persist the user's choice (e.g., in `localStorage`) so it survives page reloads. Optionally default to the system preference (`prefers-color-scheme`) on first visit.

## Admin panel (authenticated)

- Authentication for admin users.
- Create, edit, and delete blog posts (full CRUD).
- A **Markdown editor** for writing post content, ideally with a live preview.
- Draft vs. published states.
- Image upload and management for cover images and inline images.

## Technical stack & preferences

- **Framework:** Ruby on Rails (please state the Rails version you're assuming).
- **Database:** PostgreSQL.
- **Authentication:** JWT token-based authentication. Recommend a sensible approach for issuing, storing, and verifying JWTs in a server-rendered Rails app, and explain the trade-offs (e.g., where the token lives, expiry/refresh strategy, protecting admin routes).
- **Password storage:** Hash every user/admin password with Argon2 before it is stored. Passwords must never be stored in plaintext or with reversible encryption. Existing non-Argon2 password digests should be reset or migrated by asking the user for a new password, because plaintext passwords cannot be recovered from old hashes.
- **Image storage:** MinIO (S3-compatible). Configure Active Storage to use MinIO as the storage backend via the S3 adapter, and explain the bucket/credentials setup.
- **Markdown rendering:** Suggest a gem (e.g., Redcarpet or Commonmarker), render post Markdown to HTML, and **sanitize the output** to prevent XSS. This is critical since post content becomes HTML on the page.

## What I'd like from you

1. Suggest a sensible app structure following Rails MVC conventions (models, controllers, namespaced `admin` routes, views, view partials for the Markdown editor and post rendering).
2. Define the data model — `Post` and `User`/`Admin` — with fields, types, and associations.
3. Walk me through the implementation **step by step** rather than dumping everything at once.
4. Flag security considerations throughout, especially:
   - JWT handling and how admin routes are protected.
   - Argon2 password hashing, password length validation, and the fact that password hashes are not reversible.
   - Markdown → HTML sanitization to prevent XSS.
   - Strong parameters and standard Rails protections.
   - MinIO credentials and access scoping for uploaded images.
