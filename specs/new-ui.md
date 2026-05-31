# New UI Spec

## Goals

- Content-first, distraction-free reading experience
- Every interactive element must earn its place — nothing decorative
- Fast: no JavaScript required to read; JS enhances reactions/comments only
- Fully accessible (keyboard navigable, semantic HTML, ARIA where needed)
- Dark mode support on every new component

---

## Language toggle (EN / PT)

A single button in the header allows readers to switch between English and Portuguese. The choice is
stored in a cookie (`locale`) and applied server-side on every request.

- Displays the opposite of the current locale: shows **PT** when in English, **EN** when in Portuguese
- Clicking sends `GET /set_locale/:locale` and redirects back to the current page
- Default locale is English
- No JavaScript required — pure link

## Reader reactions

Below the post body, readers see a row of 6 emoji buttons. Each shows the current total count for
that reaction type. Readers can react without logging in; identity is tracked by a session cookie
(`reader_id`, a UUID set on first visit).

| Emoji | Type key |
|-------|----------|
| 👍 | like |
| ❤️ | heart |
| 😂 | haha |
| 😮 | wow |
| 😢 | sad |
| 🔥 | fire |

Rules:
- One reaction per type per session per post (unique index enforces this server-side)
- A reader may have multiple different reaction types on the same post
- Clicking an active reaction removes it (toggle)
- Count updates optimistically in the UI via Stimulus; rolls back on error
- Active reactions are highlighted with a filled background

## Comments

Below reactions, readers can leave a comment without creating an account.

Fields:
- **Name** — required, displayed publicly
- **Email** — optional, never displayed (reserved for gravatar or future use)
- **Comment** — required, max 2000 characters

Rules:
- Comments are auto-approved and immediately visible
- Displayed oldest-first in a chronological list
- Each comment shows author name and relative timestamp
- Admin can delete any comment from the admin post view
- No editing or deleting by the reader after submission

## Admin: comment moderation

On the admin post show page, a new section lists all comments on that post with a Delete button per
comment. Deletion is immediate (no soft-delete in this iteration).

---

## Acceptance criteria

- `GET /` renders the post list; locale toggle and theme toggle visible in header
- Clicking the locale button switches all UI text between English and Portuguese
- `GET /posts/:slug` shows reactions bar and comments section below the post body
- Clicking an emoji reaction toggles it; count updates without a full page reload
- Submitting the comment form with a name and body appends the comment; blank name shows validation error
- Submitting the comment form without body shows validation error
- Admin at `/admin/posts/:slug` sees a comments list with per-comment delete buttons
- Deleting a comment from admin removes it immediately
- All public-facing text is translated in both locales
