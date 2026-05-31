# Auto-Translation (PT → EN)

## What this is

When an admin publishes a post written in Portuguese, the blog automatically produces an English
version using an open-source neural machine translation model running in its own Docker container.
Readers who switch to English see the translated title, excerpt, and full post body. No human
intervention, no third-party API, no cost per character — the model runs entirely on your own
infrastructure.

---

## Why use it

The blog is written in Portuguese. Without translation, English-speaking readers either can't read
the content or have to rely on browser-level translation that breaks the layout and loses formatting.

The alternative — writing every post twice — is a workflow that doesn't scale and is easy to forget.
Automatic translation solves this at publish time: one markdown file, two language audiences.

**Why run the model yourself instead of using an API (Google Translate, DeepL)?**

- No API key, no billing, no usage limits
- Data stays on your VPS — post drafts never leave your network
- The model is purpose-built for this language pair and produces consistent quality
- Works offline; no external dependency that can go down or change pricing

---

## Technologies

### Helsinki-NLP / Opus-MT

[Helsinki-NLP](https://github.com/Helsinki-NLP/Opus-MT) is a research project at the University of
Helsinki that trained and released hundreds of open-source neural machine translation models, one per
language pair. The models are based on the **MarianMT** architecture — a sequence-to-sequence
transformer trained on the OPUS parallel corpus (millions of aligned sentence pairs from open sources
like Wikipedia, EU documents, and subtitles).

The model used here is `opus-mt-ROMANCE-en`: translates from any Romance language (Portuguese,
Spanish, French, Italian, Romanian) to English. It requires a `>>en<<` language prefix at the start
of each segment so it knows which Romance language it's reading and which target to produce. The
model weights (~300 MB) are baked into the Docker image at build time so the container is fully
self-contained.

### HuggingFace Transformers

The Python `transformers` library by HuggingFace provides a unified interface to load and run
pre-trained models. `MarianTokenizer` handles text → token IDs and back, and `MarianMTModel`
runs the actual inference. The library downloads model weights from HuggingFace Hub on first use
(baked in during `docker build`).

### FastAPI

A minimal Python web framework used to wrap the model in an HTTP server. The container exposes
two endpoints:

- `POST /translate` — accepts `{"text": "..."}`, returns `{"translation": "..."}`
- `GET /health` — returns `{"status": "ok"}` for the Docker healthcheck

### Rails Active Job + Solid Queue

Rails' Active Job provides a queue abstraction. `solid_queue` (already in the Gemfile) stores jobs
in PostgreSQL — no Redis or RabbitMQ needed. When a post is published, `TranslatePostJob` is
enqueued. It runs asynchronously so the admin's publish action returns immediately; the translation
happens in the background.

### Docker networking

The translator runs as a separate service on the same Docker network (`blog-dev`) as the Rails app.
Rails calls it by its service name (`http://translator:8000`) — no external ports needed. The URL
is configured via the `TRANSLATION_SERVICE_URL` environment variable.

---

## How it was built

### 1. Choosing the model

The original plan used `Helsinki-NLP/opus-mt-pt-en` but that model identifier does not exist on
HuggingFace Hub. The research pointed to individual language-pair models, but the PT→EN one was
only available in the Opus-MT-train training repository, not published as a ready-to-download
checkpoint. The working alternative is `opus-mt-ROMANCE-en`, which covers Portuguese and produces
accurate translations.

### 2. The translation service

A new directory `translate-service/` was added at the repo root containing three files:

**`main.py`** — loads the model at startup, splits incoming text on double newlines (so each
Markdown paragraph is translated independently, preserving structure), prepends `>>en<<` to each
segment, runs inference, and joins the results back together.

**`Dockerfile`** — installs CPU-only PyTorch explicitly via the PyTorch wheel index
(`https://download.pytorch.org/whl/cpu`) before running `pip install -r requirements.txt`. This
avoids the default PyPI behaviour of pulling CUDA libraries, which adds 2+ GB to the image size
for no benefit on a CPU-only VPS. The model is then downloaded with a `RUN python -c "..."` step
so the image is self-contained at build time.

**`requirements.txt`** — pins `fastapi`, `uvicorn`, `transformers`, and `sentencepiece` (needed
by the Marian tokenizer). `torch` is not listed here because it is installed separately in the
Dockerfile with the CPU index URL.

### 3. Docker Compose wiring

The `translator` service was added to `.devcontainer/docker-compose.yml`:
- Built from `translate-service/Dockerfile`
- Healthcheck polling `GET /health` every 30s with a 60s start period (the model takes ~5s to load)
- The `app` service depends on `translator` reaching healthy before Rails starts
- `TRANSLATION_SERVICE_URL: http://translator:8000` is injected into the app container

### 4. Database migration

Four columns were added to `posts`:

| Column | Purpose |
|--------|---------|
| `title_en` | Translated title |
| `excerpt_en` | Translated excerpt |
| `body_markdown_en` | Full translated markdown body |
| `translation_status` | `pending` → `translating` → `done` / `failed` |

### 5. Rails service object

`app/services/translation_service.rb` wraps `Net::HTTP` (Ruby stdlib, no new gem) to POST to the
translator. It raises `TranslationService::UnavailableError` on connection failure or non-200
response so Active Job can handle retries separately from other errors.

### 6. Background job

`app/jobs/translate_post_job.rb`:

1. Guards against missing or unpublished posts (idempotent)
2. Sets `translation_status = "translating"` immediately so the admin badge updates
3. Translates title, excerpt, and body markdown as three separate API calls
4. Reconstructs `body_markdown_en` following the same `# Title\n\nexcerpt\n\n---\n\nbody` pattern
   the editor writes, so the existing `extract_from_markdown` callback stays compatible
5. Saves all three EN columns and sets status to `done` in a single `update_columns` call
6. On `UnavailableError`: retries up to 5 times with `polynomially_longer` backoff
7. On any other error: sets status to `failed` and re-raises for logging

### 7. Model trigger

A single `after_save` callback on `Post` enqueues the job when `saved_change_to_status?` is true
and the new status is `published`. Re-saving a published post (e.g. editing the body) does not
re-enqueue, keeping translation costs zero for edits.

### 8. Localized display

Three methods on `Post` — `localized_title`, `localized_excerpt`, `localized_body` — return the EN
version when `I18n.locale == :en` and the EN columns are present, otherwise fall back to the
Portuguese original. This means readers switching to English before translation finishes always see
content — never blank fields.

The public post listing (`_post.html.erb`) and show page (`show.html.erb`) were updated to call
these methods instead of the raw columns.

### 9. Admin visibility

The admin post list shows an `EN: pending / translating / done / failed` badge alongside the
existing `draft / published` badge, colour-coded so the admin can tell at a glance which posts
have a ready English version.

---

## Request flow when publishing

```
Admin clicks Publish
       ↓
PATCH /admin/posts/:slug  { status: "published" }
       ↓
Post saved → assign_published_at sets published_at
       ↓
after_save callback → TranslatePostJob.perform_later(post.id)
       ↓ (returns immediately — admin sees "Post updated.")
       ↓
[background]
       ↓
TranslatePostJob#perform
  ├── translation_status = "translating"
  ├── TranslationService.translate(title)  → POST http://translator:8000/translate
  ├── TranslationService.translate(excerpt)
  ├── TranslationService.translate(body_markdown)
  └── update_columns(title_en, excerpt_en, body_markdown_en, translation_status: "done")
       ↓
Reader switches to EN → localized_title / localized_body return EN columns
```

---

## Running the translator locally

The translator image is built once and reused. It is included in the dev container stack
automatically when you run `docker compose up`. It starts **in the background** — it does not block
the devcontainer or the Rails app from opening. The model takes ~60 seconds to load; until then,
translation jobs are queued and retry automatically once the service is healthy.

To build and test it manually:

```bash
# Build (downloads model ~300 MB — takes 3-5 minutes on first build)
docker build -t blog-translator translate-service/

# Run standalone
docker run -p 8000:8000 blog-translator

# Health check
curl http://localhost:8000/health
# {"status":"ok"}

# Translate
curl -X POST http://localhost:8000/translate \
  -H "Content-Type: application/json" \
  -d '{"text":"Olá mundo, como vai você?"}'
# {"translation":"- Hello world, how are you?"}
```

---

## Known limitations

- The `>>en<<` prefix sometimes appears in the translated output for very short inputs (single words,
  proper nouns). This is a quirk of the ROMANCE-en multi-target model. A dedicated PT→EN checkpoint
  would avoid it but one is not available on HuggingFace Hub.
- Translation runs once at publish time. If the Portuguese content is later edited, the English
  version is not automatically updated — the admin must re-publish (change status to draft and back
  to published) to trigger a new translation.
- The model runs on CPU. On a small VPS, translating a long post may take 10–30 seconds. The job
  runs in the background so this is invisible to the admin.
