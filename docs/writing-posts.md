# Writing Posts

## The markdown pattern

Posts are written as a single Markdown file. The admin editor has one textarea — no separate title, slug, or excerpt fields. Everything is extracted from the content automatically on save.

```markdown
# Post Title

One-paragraph summary that becomes the excerpt.
Keep it under 500 characters.

---

Your content starts here. Everything after the first paragraph
is the body shown to readers.

## Section heading

**Bold**, *italic*, [links](https://example.com), `inline code`

```python
# fenced code blocks work too
def hello():
    print("Hello")
```

| Column A | Column B |
|----------|----------|
| Tables   | work     |
```

## What gets extracted

| Markdown element | Becomes |
|------------------|---------|
| First `# ` heading | `title` |
| First paragraph after title (up to `---`) | `excerpt` |
| Title parameterized | `slug` (e.g. `my-post-title`) |

The slug is generated once on creation. Editing the title later does **not** change the slug — existing URLs stay stable.

## Status and scheduling

- **Draft** — visible only in the admin panel, never shown publicly.
- **Published** — visible publicly as soon as `published_at` is in the past.
- Setting status to Published automatically fills `published_at` with the current time if it is blank.
- You can schedule a future post by setting `published_at` to a future date — it will appear on the blog only after that time passes.
- Changing a published post back to Draft clears `published_at`.

## Supported Markdown features

| Feature | Syntax |
|---------|--------|
| Headings | `#`, `##`, `###` … `######` |
| Bold | `**bold**` |
| Italic | `*italic*` |
| Strikethrough | `~~struck~~` |
| Inline code | `` `code` `` |
| Fenced code block | ` ```lang ` |
| Link | `[text](url)` |
| Image | `![alt](url)` |
| Blockquote | `> text` |
| Unordered list | `- item` |
| Ordered list | `1. item` |
| Table | `| col | col |` with header row |
| Horizontal rule | `---` |
| Autolink | bare URLs are linked automatically |

All rendered HTML is sanitized. `<script>` tags and `javascript:` URLs are stripped. Links open in a new tab with `rel="nofollow noopener"`.

## Admin panel

Sign in at `/superadmin/login`. There is no link to this page from the public blog — it is intentionally hidden.

After signing in, the admin panel is at `/admin`. From there you can:
- List all posts (drafts and published)
- Create a new post
- Edit or delete any post
- View and delete reader comments on each post
