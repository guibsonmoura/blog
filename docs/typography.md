# Typography & Reading Comfort

## Reading-comfort palette

Based on research in visual ergonomics, pure white (`#FFFFFF`) backgrounds with pure black (`#000000`) text cause eye strain during long reading sessions. The blog uses a softer palette:

| Role | Light mode | Dark mode |
|------|-----------|-----------|
| Page background | `#FAFAF7` (paper-like) | `#1a1a1a` (soft dark) |
| Body text | `#222222` (near-black) | `#e8e6e1` (warm off-white) |
| Excerpt text | `#444444` | `#b0ada6` |

Applied via CSS component classes in `app/assets/tailwind/application.css`:
- `.reading-surface` on `<body>` — page background + text colour
- `.reading-header` on the site header — matching frosted-glass background
- `.reading-title` on the post `<h1>` — heading colour
- `.reading-excerpt` on the excerpt `<p>` — excerpt colour + 18px / 1.7 line-height

Body prose inside `.markdown` also uses `font-size: 18px` and `line-height: 1.7` as recommended for comfortable on-screen reading.

---

## Heading hierarchy

| Markdown | HTML | Alignment | Size |
|----------|------|-----------|------|
| `# Title` | `<h1>` | **centered** | `text-4xl` (view header) / `text-3xl` (.markdown) |
| `## Section` | `<h2>` | **left** | `text-2xl` |
| `### Subsection` | `<h3>` | **left** | `text-xl` |

The `# Title` at the top of every post is extracted by `Post#extract_from_markdown` and displayed in the view header as a standalone centered `<h1>`. It is stripped from the rendered body to avoid duplication.

---

## Table of contents (TOC)

A sticky sidebar on the right lists all `##` and `###` headings when a post has at least one. It is hidden on mobile and only visible at the `lg:` breakpoint.

### How anchors are generated

Redcarpet's `with_toc_data: true` option adds `id` attributes to every heading. Its algorithm (from hoedown's C source):

- ASCII alphanumeric / hyphen / underscore → kept (lowercased)
- Spaces → `-`
- **Non-ASCII bytes → `-`** (each byte independently, then consecutive hyphens collapsed)
- Other ASCII chars → removed

Example: `## Primeira Seção`
- `ç` = UTF-8 bytes `0xC3 0xA7` → two `-` → collapse → one `-`
- `ã` = UTF-8 bytes `0xC3 0xA3` → same
- Result: `id="primeira-se-o"`

`Post#heading_anchor` in `app/models/post.rb` replicates this exactly so the TOC `href="#primeira-se-o"` matches the heading `id="primeira-se-o"`:

```ruby
def heading_anchor(text)
  text.downcase
      .gsub(/[^a-z0-9_\s-]/) { |c| c.ord > 127 ? "-" : "" }
      .gsub(/\s+/, "-")
      .gsub(/-+/, "-")
      .strip
end
```

### Why `data-turbo="false"` on TOC links

Without this attribute Turbo Drive intercepts the `href="#anchor"` click. If the anchor target doesn't exist (e.g. due to a mismatched slug), Turbo falls back to a full page visit, which can surface a cached snapshot in a different locale — making the page appear to switch language. The `data-turbo="false"` attribute delegates fragment navigation entirely to the browser.

---

## Translation service and headings

The Opus-MT model (`opus-mt-ROMANCE-en`) can mangle markdown heading syntax. Given `>>en<< ### Uma Subseção` it may output `- ### A subsection` (treating `###` as notation inside a list item).

The fix in `translate-service/main.py`: detect heading lines with `HEADING = re.compile(r"^(#{1,6})\s+(.+)$")`, translate only the text portion, then re-attach the `#` prefix:

```python
heading_match = HEADING.match(segment)
if heading_match:
    prefix = heading_match.group(1)        # e.g. "###"
    label  = heading_match.group(2)        # e.g. "Uma Subseção"
    translated_label = run_model(label).lstrip("- ").strip()
    translated_segments.append(f"{prefix} {translated_label}")
    continue
```

The `.lstrip("- ")` strips another common model artifact where short phrases are prefixed with `- `.

---

## Post body duplication fix

The post show view displays title and excerpt separately in a `<header>`. Without stripping, `localized_body` would render the full markdown and show the `# Title` and excerpt paragraph a second time.

`Post#strip_header` in `app/models/post.rb` removes this header section before rendering:

1. If a `---` separator exists → return everything after it
2. If no separator → skip the leading `#` heading and the first paragraph, return the rest

This means a post with no body content beyond the excerpt correctly shows an empty `.markdown` area with no duplication.
