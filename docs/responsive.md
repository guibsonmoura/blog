# Responsive Design & The Galaxy Fold Overflow Bug

## Overview

The blog is mobile-first and must render without horizontal scrolling on any screen down to
**344px** (Samsung Galaxy Fold, the narrowest mainstream viewport). This document records the
responsive rules **and** the debugging story of a horizontal-overflow bug that was unusually hard
to pin down — so it's never re-debugged from scratch.

---

## Breakpoints

| Name | Min width | Used for |
|------|-----------|----------|
| base | 0px | Mobile-first defaults (Galaxy Fold 344px and up) |
| `xs` *(custom)* | 375px | Show LinkedIn icon in header |
| `sm` | 640px | Show "Sobre" text link; larger hero/title |
| `lg` | 1024px | Two-column layouts (feed + sidebar, post + TOC) |

`xs` is a custom Tailwind v4 variant in `app/assets/tailwind/application.css`:

```css
@custom-variant xs (@media (width >= 375px));
```

## Layout per page

| Page | < 1024px (mobile/tablet) | ≥ 1024px (`lg`) |
|------|--------------------------|-----------------|
| Home | Single column, sidebar hidden | Feed + 240px sidebar |
| Post | Single column, TOC hidden | Article + 220px TOC |
| About | Single column, `max-w-2xl` | Same |

The sidebar and TOC use `hidden lg:block` — they never render on mobile.

---

## The horizontal-overflow bug (root cause + fix)

### Symptom

On a Galaxy Fold (344px) in Chrome DevTools device mode, the page scrolled horizontally — but a
DOM scan (`getBoundingClientRect().right > clientWidth` for every element) reported **zero
overflowing elements**. Headless Chrome at the same viewport showed `scrollWidth === clientWidth`
(no overflow at all). Instruments and the real browser disagreed.

### Why it was hard

A per-element overflow scan only catches elements whose *own* box exceeds the viewport. It misses:
- text nodes (not elements)
- elements whose **pre-transform** box is wide but is visually pulled back by a `transform`
- scrollable-overflow contributed by `position: fixed`/absolute descendants

The scan returning "0 offenders" sent the investigation down the wrong path (cache, stale assets)
for a long time.

### Actual cause

The **hidden search modal** in the layout:

```erb
<div class="fixed left-1/2 top-[15vh] w-full max-w-xl -translate-x-1/2 px-4">
```

This pattern — `left: 50%` + `width: 100%` (of viewport, because `fixed`) + `translateX(-50%)` —
means the element's **pre-transform box spans from 50% to 150% of the viewport width**. The
translate only pulls it back *visually*. In several Chrome builds this still contributes to the
page's scrollable-overflow region, producing horizontal scroll **even though the element is
nominally hidden and no element's final rect exceeds the viewport**. That's exactly why the scan
found nothing.

Search had already been hidden from the UI, so this modal was dead markup.

### Fix

1. **Removed the dead search modal entirely** from `app/views/layouts/application.html.erb`.
2. Switched the root overflow guard from `overflow-x: clip` to plain `overflow-x: hidden` on
   `html` and `body` (`clip` has cross-version quirks on the root element; `hidden` is universal
   and does not break the body-level `position: sticky` header in modern Chrome).
3. Strengthened word-breaking to `overflow-wrap: anywhere` on all text elements so long unbreakable
   strings (URLs, hashes) wrap instead of widening the page.

```css
html  { overflow-x: hidden; width: 100%; }
body  { position: relative; width: 100%; max-width: 100%; overflow-x: hidden; }
p, li, td, th, blockquote, figcaption, h1, h2, h3, h4, a, span {
  overflow-wrap: anywhere;
  word-break: break-word;
}
*, *::before, *::after { box-sizing: border-box; }
```

---

## Defensive rules in place

These prevent the common overflow sources globally (in `app/assets/tailwind/application.css`):

- `box-sizing: border-box` on everything — padding never adds to element width.
- `img, video, iframe, embed, object { max-width: 100%; height: auto; }` — media is fluid.
- `input, textarea, select { max-width: 100%; }` — form fields can't bust their container.
- `.markdown pre` → `overflow-x: auto` (code blocks scroll internally).
- `.markdown table` → `display: block; overflow-x: auto` (wide tables scroll, don't break layout).
- Grid/flex content columns use `min-w-0 overflow-hidden` so a track never grows past its cell.

---

## How to debug horizontal overflow (the right way)

A per-element `getBoundingClientRect` scan is **not enough** — it misses the cases above. Use all of:

1. **Compare the two numbers**, not the element count:
   ```js
   const de = document.documentElement;
   console.log("viewport", de.clientWidth, "scrollWidth", de.scrollWidth,
               "canScroll", de.scrollWidth > de.clientWidth);
   ```
   If `scrollWidth === clientWidth` the scroll is a device-mode artifact, not real.

2. **Headless measurement at multiple widths** with the overflow guard temporarily disabled
   (so the guard doesn't mask the true `scrollWidth`). Script kept at
   `tmp/overflow-check/deep.mjs` during development.

3. **Grep the views for the usual culprits** before scanning the DOM:
   ```
   100vw   w-screen   -translate   -m[lrtxy]-   whitespace-nowrap
   ```
   The `w-full + left-1/2 + -translate-x-1/2` centering trick is the highest-risk pattern.

4. **Bypass cache properly**: DevTools → Network → ☑ Disable cache → Empty Cache and Hard Reload.
   The compiled CSS is served `immutable` for a year; a soft refresh can show stale styles.

---

## Acceptance criteria

- No horizontal scrollbar at 320 / 344 / 360 / 375 / 414 / 768 / 1024 / 1280 px.
- Sidebar and TOC hidden below `lg`; single-column content on mobile.
- Header sticky and fully visible at every width; icons fit on one row at 344px.
- All interactive elements ≥ 44px tall (touch targets).
- Long unbreakable strings wrap; code blocks and tables scroll internally.
