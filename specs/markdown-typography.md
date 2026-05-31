# Markdown Typography Spec

## Goal

Ensure every post body renders with consistent, readable visual hierarchy and alignment.
The rules are intentionally simple: headings map directly to their semantic HTML level,
and all paragraph text is fully justified so the reading column has clean left and right edges.

---

## Rules

### Heading hierarchy

| Markdown | HTML tag | Role |
|----------|----------|------|
| `# Heading` | `<h1>` | Post title — one per post, large, bold |
| `## Heading` | `<h2>` | Section heading — primary subdivision |
| `### Heading` | `<h3>` | Sub-section heading |
| `#### Heading` | `<h4>` | Minor heading (used sparingly) |

The `#` at the top of every post is already used to auto-extract the post title
(`Post#extract_from_markdown`). When the full markdown is rendered in the public
post view (`show.html.erb`), that `# Title` line must render as a visible `<h1>`
inside the `.markdown` div — large, bold, and matching the heading scale.

### Text justification

All paragraph text (`<p>`) inside the `.markdown` content area must be
**fully justified** (`text-align: justify`) so both left and right edges of every
paragraph are flush with the container. This applies to:
- Regular prose paragraphs
- Blockquote text
- List item text

It does **not** apply to:
- Code blocks (`<pre>`, `<code>`) — left-aligned, monospace
- Table cells — left-aligned by default
- Headings — centered (see below)

### Heading alignment

- `<h1>` — **centered** (`text-align: center`). The post title stands alone, above everything.
- `<h2>` — **left-aligned**. Section subtitles anchor the start of a new block of content.
- `<h3>` and below — **left-aligned**. Blend with surrounding text flow.

The post title displayed in the view `<header>` (outside `.markdown`) is also centered via
`text-center` directly on the element. The excerpt paragraph in the header is justified.

---

## Scope

Changes are limited to `app/assets/tailwind/application.css` — the `.markdown`
component styles. No controller, model, or route changes are needed.
The Redcarpet renderer already produces correct semantic HTML (`h1`, `h2`, `p`, etc.);
this spec is purely about how those elements are styled.

---

## Acceptance criteria

- A post containing `# Title`, `## Section`, and prose renders with visually
  distinct `<h1>` and `<h2>` elements inside `.markdown`
- Post header `<h1>` (view title) is centered
- `<h1>` inside `.markdown` is centered
- `<h2>` inside `.markdown` is left-aligned
- `<h3>` and below remain left-aligned
- All `<p>` inside `.markdown` have `text-align: justify`
- Code blocks remain left-aligned and unaffected by justification
- Dark mode parity: heading colours and paragraph justification work in both themes
- Existing test suite passes without changes
