# Authentication Spec

## Goal

Provide a hidden admin login path (`/superadmin/login`) so that only people who know the URL can
access the admin panel. No link or hint pointing to the admin area must be visible on public pages.

## Login flow

1. Admin navigates to `/superadmin/login`.
2. Submits email + password via `POST /superadmin/login`.
3. On success: JWT is written to an encrypted HTTP-only cookie (`admin_token`, 12-hour expiry) and
   the user is redirected to `/admin` (post list).
4. On failure: form re-renders with a generic error ("Invalid email or password.") and HTTP 422.
5. If already authenticated, `GET /superadmin/login` redirects straight to `/admin`.

## Logout

`DELETE /superadmin/logout` clears the cookie and redirects to `/superadmin/login`.

## Admin capabilities after login

| Action         | Route                    |
|----------------|--------------------------|
| List posts     | `GET /admin/posts`       |
| View post      | `GET /admin/posts/:slug` |
| New post form  | `GET /admin/posts/new`   |
| Create post    | `POST /admin/posts`      |
| Edit post form | `GET /admin/posts/:slug/edit` |
| Update post    | `PATCH /admin/posts/:slug` |
| Delete post    | `DELETE /admin/posts/:slug` |

## Public interface constraints

- No link, button, or reference to `/admin` or `/superadmin` must appear in any public-facing view
  or layout.
- The admin panel URL (`/admin`) is not secret, but no unauthenticated request can reach anything
  under it — all admin routes redirect to `/superadmin/login` when the cookie is absent or invalid.

## Security rules

- Only users with `admin: true` can log in; a valid email/password for a non-admin user is rejected.
- Passwords are verified with Argon2. Plaintext passwords are never stored or logged.
- JWT is signed with `JWT_SECRET` (falls back to `secret_key_base`), HS256, issuer: `blog-admin`.
- Cookie is HTTP-only, `SameSite: Lax`, and `Secure` in production.
- Rate limiting and brute-force protection are out of scope for this iteration.

## Acceptance criteria

- `GET /superadmin/login` renders the sign-in form (HTTP 200).
- `POST /superadmin/login` with valid admin credentials sets cookie and redirects to `/admin`.
- `POST /superadmin/login` with wrong password returns HTTP 422 and re-renders form.
- `POST /superadmin/login` with a non-admin user's credentials returns HTTP 422.
- `DELETE /superadmin/logout` clears the cookie and redirects to `/superadmin/login`.
- Authenticated admin can reach `GET /admin/posts`.
- Unauthenticated request to `GET /admin/posts` redirects to `/superadmin/login`.
- Public layout contains no link to any admin or superadmin path.
