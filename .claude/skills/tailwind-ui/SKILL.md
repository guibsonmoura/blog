---
name: tailwind-ui
description: Build, style, and refine Tailwind CSS UI components in this Rails app. Use when asked to design, implement, improve, or screenshot UI, views, ERB templates, or frontend styling.
---

Guide for implementing Tailwind CSS + Rails ERB UI in this project. The app uses Tailwind v4 via `tailwindcss-rails`, server-side rendering with ERB partials, Hotwire (Turbo + Stimulus), and class-based dark mode. The visual philosophy is **minimalist and content-first**: neutral palette, generous whitespace, no decorative elements.

All paths below are relative to the repo root.

## Stack facts (don't re-discover)

| What | Detail |
|---|---|
| Tailwind version | v4.x via `tailwindcss-rails` gem |
| CSS entrypoint | `app/assets/stylesheets/application.css` |
| Compiled output | `app/assets/builds/tailwind.css` (auto-rebuilt by `bin/rails tailwindcss:watch`) |
| Asset pipeline | Propshaft (not Sprockets) |
| Dark mode | Class-based — `dark` added to `<html>` by inline script in layout; toggled by Theme button |
| JS layer | Hotwire: Turbo (SPA-like navigation) + Stimulus (lightweight controllers) |
| Templates | ERB; partials under `app/views/` |
| Rebuild CSS (one-shot) | `bin/rails tailwindcss:build` (run inside container or via `docker exec`) |

## Design system

### Color palette

Use **neutral + blue** — no other hue families unless there is a semantic reason (red = destructive, emerald = success).

| Role | Light | Dark |
|---|---|---|
| Page background | `stone-50` / `bg-white` | `neutral-950` |
| Primary text | `neutral-950` | `neutral-100` |
| Secondary text | `neutral-600` | `neutral-400` |
| Borders | `neutral-200` | `neutral-800` |
| Primary action | `neutral-950` bg + white text | `neutral-100` bg + `neutral-950` text |
| Hover (action) | `blue-700` bg | `blue-200` bg |
| Link/accent | `blue-700` | `blue-300` |
| Success | `emerald-50` bg, `emerald-800` text, `emerald-300` border | dark variants |
| Error / alert | `red-50` bg, `red-800` text, `red-300` border | dark variants |

### Typography

System font stack — no web fonts loaded. Optimise for readability, not branding.

| Use | Classes |
|---|---|
| Page title / hero | `text-4xl font-semibold leading-tight` |
| Section heading | `text-3xl font-semibold` |
| Card title | `text-xl font-semibold` |
| Label / eyebrow | `text-sm uppercase tracking-[0.18em] text-neutral-500` |
| Body text | `text-lg leading-8` (articles) or `text-base leading-7` (UI) |
| Caption / meta | `text-sm text-neutral-600 dark:text-neutral-400` |
| Monospace | `font-mono text-sm` |

### Spacing

Max-width containers: `max-w-5xl mx-auto px-5` (standard page), `max-w-3xl` (content-heavy), `max-w-sm` (narrow forms).

Vertical rhythm: `py-12` between major sections; `space-y-5` or `space-y-8` within a section. Don't mix arbitrary values — stick to the Tailwind scale.

### Radius & borders

- Interactive elements: `rounded-md` (inputs, buttons, cards)
- Pills / badges: `rounded-full`
- Dividers: `divide-y divide-neutral-200 dark:divide-neutral-800`
- Section separators: `border-t border-neutral-200 dark:border-neutral-800`

## Component recipes (verified patterns from this codebase)

### Primary button
```erb
<%= submit_tag "Save", class: "rounded-md bg-neutral-950 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 dark:bg-neutral-100 dark:text-neutral-950 dark:hover:bg-blue-200" %>
```

### Secondary / outline button
```erb
<%= link_to "Cancel", root_path, class: "rounded-md border border-neutral-300 px-4 py-2 text-sm text-neutral-700 hover:border-neutral-500 hover:text-neutral-950 dark:border-neutral-700 dark:text-neutral-300 dark:hover:border-neutral-500 dark:hover:text-neutral-50" %>
```

### Text input
```erb
<%= f.text_field :title, class: "mt-2 w-full rounded-md border border-neutral-300 bg-white px-3 py-2 text-neutral-950 shadow-sm focus:border-blue-600 focus:outline-none dark:border-neutral-700 dark:bg-neutral-900 dark:text-neutral-50" %>
```

### Textarea
Same classes as text input, add `rows: 6`.

### Form field wrapper (label + input)
```erb
<div>
  <%= f.label :title, class: "block text-sm font-medium text-neutral-700 dark:text-neutral-300" %>
  <%= f.text_field :title, class: "mt-2 w-full rounded-md border ..." %>
</div>
```

### Flash / alert banner
```erb
<% if notice %>
  <div class="rounded-md border border-emerald-300 bg-emerald-50 px-4 py-3 text-emerald-800 dark:border-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">
    <%= notice %>
  </div>
<% end %>
```

### Status badge
```erb
<span class="rounded-full border border-neutral-300 px-2.5 py-1 text-xs capitalize text-neutral-700 dark:border-neutral-700 dark:text-neutral-300">
  <%= post.status %>
</span>
```

### Post card (two-column with image)
```erb
<article class="grid gap-6 md:grid-cols-[180px_1fr]">
  <div class="aspect-[4/3] overflow-hidden rounded-md border border-neutral-200 dark:border-neutral-800">
    <%# image or placeholder %>
  </div>
  <div>
    <h2 class="text-xl font-semibold"><%= post.title %></h2>
    <p class="mt-2 text-sm text-neutral-600 dark:text-neutral-400"><%= post.excerpt %></p>
  </div>
</article>
```

### Section header (eyebrow + title)
```erb
<header class="mb-10">
  <p class="text-sm uppercase tracking-[0.18em] text-neutral-500">Blog</p>
  <h1 class="mt-3 text-4xl font-semibold leading-tight text-neutral-950 dark:text-neutral-100">
    Latest posts
  </h1>
</header>
```

### Data table (admin)
```erb
<div class="overflow-x-auto">
  <table class="w-full text-sm">
    <thead class="border-b border-neutral-200 dark:border-neutral-800">
      <tr class="text-left text-neutral-500">
        <th class="pb-3 font-medium">Title</th>
      </tr>
    </thead>
    <tbody class="divide-y divide-neutral-200 dark:divide-neutral-800">
      <% @posts.each do |post| %>
        <tr class="py-4">
          <td class="py-4"><%= post.title %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

## UX principles for this project

1. **Whitespace is the primary design element.** When in doubt, add more padding. Never crowd elements.
2. **One action per page wins.** Primary CTA is dark background + white text; everything else is outline or text-only.
3. **Color means something.** Blue = interactive. Red = destructive. Emerald = success. Neutral = structure. Don't use color decoratively.
4. **Dark mode is first-class.** Every new element needs paired `dark:` classes. Test with `localStorage.setItem('theme','dark')` in browser console then refresh.
5. **No client-side state for content.** Rails renders HTML; Stimulus handles micro-interactions only (theme toggle, preview, file upload UI). Don't reach for JS when a partial + Turbo Frame works.
6. **Responsive defaults.** Mobile-first. Use `md:` for two-column layouts; `lg:` only when content genuinely needs it.

## Workflow for implementing a new UI element

```powershell
# 1. Edit the ERB template (on Windows host — mounted into container)
#    Files live at D:\projetos\blog\app\views\...

# 2. Rebuild Tailwind (needed when adding new classes)
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails tailwindcss:build"

# 3. Verify the page renders
$resp = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing
$resp.StatusCode   # should be 200

# 4. Check for dark mode parity
#    In browser console: localStorage.setItem('theme','dark'); location.reload()
#    Then: localStorage.setItem('theme','light'); location.reload()
```

If the Tailwind watcher is running (`bin/rails tailwindcss:watch` via `bin/dev`), step 2 happens automatically on file save — skip it.

## Adding a new view file

Follow this shell for any new page:

```erb
<%# app/views/namespace/action.html.erb %>
<div class="mx-auto max-w-5xl px-5 py-12">
  <header class="mb-10">
    <p class="text-sm uppercase tracking-[0.18em] text-neutral-500">Section label</p>
    <h1 class="mt-3 text-4xl font-semibold leading-tight text-neutral-950 dark:text-neutral-100">
      Page title
    </h1>
  </header>

  <%# content here %>
</div>
```

## Run (agent path)

```powershell
# Confirm server is up
Invoke-WebRequest -Uri "http://localhost:3000/up" -UseBasicParsing | Select-Object StatusCode

# View a page
$resp = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing
$resp.Content | Select-String '<title>' | Select-Object -First 1

# Force Tailwind rebuild after adding new utility classes
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails tailwindcss:build"
```

## Test

```powershell
docker exec devcontainer-app-1 bash -c "cd /workspace && bin/rails test"
```

There are no dedicated UI/visual tests — verify visually by loading the page.

## Gotchas

- **Tailwind v4 has no `tailwind.config.js`** — the gem manages config. Custom classes go in `app/assets/stylesheets/application.css` using `@utility` or standard CSS.
- **Propshaft doesn't fingerprint on-the-fly** — after adding a new CSS class, always run `bin/rails tailwindcss:build` if the watcher isn't running; stale compiled CSS is the #1 cause of "my class isn't working."
- **Dark mode script is inline** — the theme-detection `<script>` in `application.html.erb` runs before `<body>` to prevent flash of wrong theme. Don't move it below the fold.
- **`stone-50/90` uses opacity modifier** — the header background is `bg-stone-50/90 backdrop-blur` for a frosted-glass effect. Replicate this for any sticky/floating element.
- **`tracking-[0.18em]` is an arbitrary value** — it's used specifically for the eyebrow labels. Use it only for that role; don't scatter arbitrary tracking values.
- **Flash messages disappear on Turbo navigation** — they're rendered once per page visit. Use `flash.now` for form re-renders; `flash` (not `.now`) for redirects.
