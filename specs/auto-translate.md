# Auto-Translation Spec (PT → EN)

## Goal

When an admin publishes a post (written in Portuguese), the system automatically produces an English translation and stores it alongside the original. Readers who select English see the translated content. The translation runs in the background after publish — readers see the Portuguese content immediately while the job processes.

---

## Translation service

A dedicated Docker container (`translator`) runs a FastAPI server backed by the `Helsinki-NLP/opus-mt-pt-en` model from HuggingFace. It exposes a single translation endpoint. The model is baked into the image at build time so it starts with no external downloads.

**API contract:**

```
POST /translate
Content-Type: application/json
Body: {"text": "Texto em português"}

200 OK
{"translation": "Text in English"}

GET /health
200 OK
{"status": "ok"}
```

The container is CPU-only (GPU optional). RAM requirement: 2–4 GB. It runs on the same Docker network as the Rails app (`blog-dev`) and is reachable at `http://translator:8000`.

---

## Trigger

An `after_save` callback on `Post` enqueues `TranslatePostJob` whenever `status` changes to `published`. If a published post is edited and re-saved without a status change, the job is NOT re-enqueued (only runs on status transition). If a post reverts to draft, any existing translation is preserved but the status badge resets to `pending` for when it's re-published.

---

## Storage

Four new columns on `posts`:

| Column | Type | Notes |
|--------|------|-------|
| `title_en` | string | Translated title |
| `excerpt_en` | string | Translated excerpt |
| `body_markdown_en` | text | Full translated markdown (same `# Title\n\nexcerpt\n\n---\n\nbody` pattern) |
| `translation_status` | string | `pending` / `translating` / `done` / `failed` |

`translation_status` defaults to `pending`. It lets the admin see at a glance whether the EN version is ready.

---

## Translation job

`TranslatePostJob` (queued via `solid_queue`):

1. Finds post by ID — exits silently if post not found or not published
2. Sets `translation_status = "translating"`
3. Translates `title`, `excerpt`, and `body_markdown` as separate API calls
4. Reconstructs `body_markdown_en` following the standard markdown pattern
5. Sets `translation_status = "done"` and saves all EN columns atomically
6. On `TranslationService::UnavailableError`: retries up to 5 times with exponential backoff
7. On any other error: sets `translation_status = "failed"` then re-raises (logged by solid_queue)

---

## Display logic

| Locale | EN columns present | Shown to reader |
|--------|--------------------|-----------------|
| `:pt` | any | Portuguese original |
| `:en` | blank (`pending`/`failed`) | Portuguese original (fallback) |
| `:en` | present (`done`) | English translation |

Methods on `Post`:
- `localized_title` — `title_en` if locale is EN and present, else `title`
- `localized_excerpt` — `excerpt_en` if locale is EN and present, else `excerpt`
- `localized_body` — renders `body_markdown_en` if locale is EN and present, else `body_markdown`

---

## Admin visibility

The admin post list shows a `translation_status` badge next to the existing status badge:
- `pending` — neutral grey
- `translating` — amber
- `done` — green
- `failed` — red

---

## Acceptance criteria

- Publishing a post enqueues `TranslatePostJob` exactly once.
- After the job completes, `translation_status == "done"` and all three EN columns are populated.
- A reader in EN locale sees translated title, excerpt, and body.
- A reader in PT locale always sees the original Portuguese regardless of translation status.
- If translation fails or is pending, the EN locale reader sees the Portuguese original (no blank content).
- Re-saving a published post without changing status does NOT re-enqueue the job.
- `GET /health` on the translator returns 200.
- `POST /translate` with Portuguese text returns an English string.
