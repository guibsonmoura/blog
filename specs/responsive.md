# Responsive Design Spec

## Goal

Every page of the blog must render correctly and be comfortable to read on any screen size —
from a 320px mobile phone to a 1440px desktop. No horizontal scrolling, no clipped content,
no elements that require pinching to interact with.

---

## Breakpoints

| Name | Min width | Typical device |
|------|-----------|----------------|
| (base) | 0px | Ultra-small phones (Galaxy Fold: 344px) |
| `xs` *(custom)* | 375px | Standard small phones (iPhone SE) |
| `sm` | 640px | Large phones / small tablets |
| `md` | 768px | Tablets, landscape phones |
| `lg` | 1024px | Laptops, desktops |
| `xl` | 1280px | Wide desktops |

`xs` is a custom Tailwind v4 variant defined in `application.css`:

```css
@custom-variant xs (@media (width >= 375px));
```

---

## Layout rules per page

### All pages — Header

- **344px (Galaxy Fold):** blog name (`text-xs truncate`) + GitHub + RSS + locale + theme — exactly 4 items in the icon row. LinkedIn hidden below `xs`. Blog name truncates if needed rather than pushing nav off-screen. `overflow-hidden` on the header container prevents any bleed.
- **375px (`xs`):** LinkedIn icon visible.
- **640px (`sm`):** "Sobre" text link visible. Blog name grows to `text-sm`.
- **Desktop (`lg`):** full size, `text-base` blog name.
- Header is sticky on all screen sizes.
- `body { overflow-x: hidden; max-width: 100vw }` acts as a safety net against any stray fixed-width child.

### Homepage (`/`)

| Area | Mobile | Desktop (`lg:`) |
|------|--------|-----------------|
| Grid | Single column, full width | Two columns: `1fr 240px` |
| Hero | Left-aligned, `text-2xl` | Left-aligned, `text-3xl` |
| Year divider | Full-width rule | Full-width rule |
| Post cards | Full width, `divide-y` | Full width, `divide-y` |
| Sidebar | **Hidden** — content flows inline | Sticky right column |
| Archive counts | Below each post card as pill | Sidebar only |

On mobile, the sidebar ("Recent posts" and "Archive") is hidden. The feed is the only content.

### Post show (`/posts/:slug`)

| Area | Mobile | Desktop (`lg:`) |
|------|--------|-----------------|
| Grid | Single column | `1fr 220px` (content + TOC) |
| TOC sidebar | **Hidden** | Sticky right column |
| Reading progress bar | Present | Present |
| Article max-width | `100%` with `px-4` padding | `max-w-3xl` centred |
| Copy link / meta row | Wraps gracefully | Single row |

### About (`/about`)

- Single column on all sizes, `max-w-2xl` centred.
- Tech badges wrap naturally.

---

## Typography scaling

| Element | Mobile | Desktop |
|---------|--------|---------|
| Hero name | `text-2xl` | `text-3xl` |
| Post title (feed) | `text-base font-semibold` | `text-base font-semibold` |
| Post title (show) | `text-3xl` | `text-4xl` |
| Excerpt | `text-sm` | `text-sm` |
| Body prose | `text-base` (16px) | 18px (`.markdown`) |
| Year eyebrow | `text-xs` | `text-xs` |

---

## Touch targets

All interactive elements must have a minimum tap area of **44px height** on mobile.
Icon buttons use `min-h-[44px] p-2` — height guaranteed by `min-h`, width kept compact
(no `min-w`) so the header fits on 344px screens. Do **not** use `min-w-[44px]` on header
icons: 4 icons × 44px = 176px plus blog name and locale text exceeds 344px usable width.

---

## Horizontal overflow

- No element may cause `overflow-x` scroll on the page.
- Code blocks inside `.markdown` use `overflow-x-auto` to scroll independently.
- Tables inside `.markdown` are wrapped in `overflow-x-auto`.
- Images are `max-w-full`.

---

## Images

- All images: `max-w-full h-auto`.
- Cover images on post show: `aspect-[16/9] w-full object-cover`.

---

## Navigation — mobile

On mobile the header shows:
1. Blog name (`guibsonmoura.com`) — left
2. Icon row (LinkedIn, GitHub, RSS, locale toggle, theme toggle) — right

If the icon row is too wide, reduce to the most essential icons and move others behind a hamburger
menu — but for now the current 5-icon set fits on a 375px screen without overflow.

---

## Acceptance criteria

- No horizontal scrollbar on any page at **344px (Galaxy Fold)**, 375px, 414px, 768px, 1024px, or 1280px viewport widths.
- Sidebar is hidden on mobile (`hidden lg:block`) and never leaks into the mobile layout.
- All text is legible without zooming (minimum 14px rendered size).
- All links and buttons are tappable without precision (44px minimum touch target).
- Post body prose never exceeds `max-w-3xl` to keep line lengths comfortable.
- TOC sidebar hidden on mobile — the post body reads as a single full-width column.
- Reading progress bar visible on both mobile and desktop.
- Header remains sticky and fully visible on all screen sizes.
