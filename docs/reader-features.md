# Reader Features

## Language toggle

A button in the header switches the UI between English and Portuguese. The choice is stored in a cookie (`locale`, 1-year expiry) and applied server-side on every request. No JavaScript required.

- Default language: **English**
- The button always shows the opposite of the current language (`PT` when in English, `EN` when in Portuguese)
- All public-facing text uses Rails i18n — translation files are in `config/locales/en.yml` and `config/locales/pt.yml`

## Emoji reactions

Below each post, readers can react with six emoji types:

| Emoji | Type |
|-------|------|
| 👍 | like |
| ❤️ | heart |
| 😂 | haha |
| 😮 | wow |
| 😢 | sad |
| 🔥 | fire |

**How it works:**
- No account required. Each reader is identified by a UUID stored in their session cookie (`reader_id`), set automatically on first visit.
- Clicking an emoji adds that reaction. Clicking it again removes it (toggle).
- A reader can have multiple different reaction types on the same post, but not the same type twice.
- Counts update optimistically via a Stimulus controller — the number changes immediately without a full page reload, and rolls back if the server returns an error.
- Active reactions are highlighted with a blue pill style.

**Implementation:** `ReactionsController#create` does a find-or-destroy toggle. The unique index on `[post_id, session_id, reaction_type]` enforces the one-per-type constraint at the database level.

## Comments

Below reactions, readers can leave a comment without creating an account.

**Fields:**
- **Name** — required, displayed publicly next to the comment
- **Email** — optional, never shown publicly (reserved for future gravatar or notification use)
- **Comment** — required, max 2000 characters

**Rules:**
- Comments are approved and visible immediately after submission
- Displayed oldest-first in a chronological list
- After submitting, the page redirects back to the comments section with a success notice
- Validation errors (blank name or body) redirect back to the comment form with an error message
- Readers cannot edit or delete their own comments after posting

**Admin moderation:** The admin post view (`/admin/posts/:slug`) shows all comments with a Delete button per comment. Deletion is permanent.
