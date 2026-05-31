# Spec — Reactions section redesign

Status: ready for implementation
Branch: `improving-reacts`
Scope: **frontend + view only** — no database, model, route, or controller-logic changes.

## 1. Goal

Turn the flat row of reaction "pills" into a **flat section** that blends with the page (no boxed
card) and presents the six reactions as a **radio family** (pick one). Reacting should feel alive:
the chosen tile **turns blue**, and a celebratory **full-viewport emoji burst** of the chosen
reaction floats up the screen and fades.

The existing backend already models exactly one reaction per visitor (click active = remove,
click another = switch), so the radio semantics are a pure UI expression of behavior that already
exists. **Nothing server-side changes.**

## 2. Out of scope

- No multi-select (checkbox) — single choice only.
- No new reaction types; the six stay: 👍 like · ❤️ heart · 😂 haha · 😮 wow · 😢 sad · 🔥 fire.
- No DB migration, no `Reaction` model change, no route change (`POST /posts/:id/reactions` stays).
- Comments are untouched.

## 3. Current state (baseline)

| File | Role today |
|---|---|
| `app/views/posts/_reactions.html.erb` | Renders one `form_with` per reaction as inline pill buttons in a `flex-wrap` row. |
| `app/javascript/controllers/reactions_controller.js` | Stimulus controller; optimistic count + active-class swap; `fetch` POST/DELETE. |
| `app/controllers/reactions_controller.rb` | `create` toggles/switches the single reaction; redirects to `#reactions`. |
| `app/models/reaction.rb` | `enum reaction_type`; one-per-identity uniqueness. |
| `config/locales/{en,pt}.yml` | `reactions.<type>` = emoji glyph. |

Known bug to fix while here: the JS sends `DELETE` to deactivate, but only `POST #create` is routed;
the controller toggles server-side on `POST`. The redesigned controller JS must **always `POST` the
`reaction_type`** and let the server toggle — never `DELETE`.

## 4. Visual / layout design

### 4.1 The section (flat, blends with the page)

The reactions live as a **flat section**, not a boxed card — visually consistent with the sibling
comments section (`app/views/posts/_comments.html.erb`). It sits directly on the page's default
reading background (no `bg-white`/card fill, no rounded box, no shadow).

- No container chrome: the `<section>` holds the header row + tile grid directly.
- Top line: provided by the shared group wrapper in `app/views/posts/show.html.erb`
  (`border-t border-neutral-200 pt-12 dark:border-neutral-800`), which sits above the reactions
  section. No extra border is added inside the partial.
- Width: flows with the article column (`max-w-3xl`).
- Header row: the eyebrow label (`t("posts.show.reactions_section")`,
  `text-sm uppercase tracking-[0.18em]`) on the left, and a small muted **total count** of all
  reactions on the right.

### 4.2 The reaction tiles (radio family)

The six reactions render as a **radio group**:

- Semantics: a `fieldset` with a visually-hidden `legend` (the section label already serves as the
  accessible group name; legend is `sr-only`). Each reaction is a real
  `<input type="radio" name="reaction" value="<type>">` visually hidden (`sr-only` / `peer`), with
  a `<label>` styled as the tile. This gives keyboard arrow-key navigation and screen-reader
  semantics for free.
- Single name (`reaction`) → browser enforces the "one of" radio family.
- The currently selected reaction (server-rendered `selected_type`) gets `checked`.
- Layout of tiles: responsive grid — `grid grid-cols-3 gap-3 sm:grid-cols-6`. Each tile fills its
  cell; tiles are equal-sized squares-ish (`aspect-square` or min-height ~`5rem`).
- Tile contents, stacked and centered: the **emoji** (`text-2xl sm:text-3xl`) above the **count**
  (`text-sm tabular-nums`). An `sr-only` text label (Like/Love/…) for the accessible name.

### 4.3 Tile states

| State | Style |
|---|---|
| Idle | `border-neutral-200 bg-transparent text-neutral-700` (+ dark variants) — transparent so the page background shows through; hover lifts border to `neutral-400` and adds `-translate-y-0.5`. |
| Focus-visible | blue focus ring (`ring-2 ring-blue-500 ring-offset-2`) on the label via `peer-focus-visible`. |
| Selected (checked) | **blue**: `border-blue-500 bg-blue-50 text-blue-700` (`dark:border-blue-600 dark:bg-blue-950/40 dark:text-blue-300`) via `peer-checked:` utilities. |

Because selection is driven by the radio `:checked` state through `peer-checked:` classes, the blue
state is correct even without JS (progressive enhancement).

## 5. Interactions / motion

### 5.1 Selection (blue) on click

When a reaction tile is activated (click / Enter / Space / arrow-select):

1. The clicked tile transitions to the **blue selected** state. With the radio `peer-checked:`
   approach this is automatic, even without JS. (No spin — the section stays still.)
2. If the visitor re-clicks the already-selected tile, it **deselects** (server removes the
   reaction): radio is unchecked, tile returns to idle, count −1. (Radios don't natively toggle off,
   so JS handles the "click the checked one to clear it" case — see §6.)

### 5.2 Full-viewport emoji burst

On a **new selection or switch** (not on deselect), fire a celebratory burst:

- Spawn ~16–24 copies of the chosen emoji as absolutely-positioned elements in a single
  `position: fixed; inset: 0; pointer-events: none; z-index: 50` overlay layer appended to
  `document.body`.
- Each emoji starts near the clicked tile's horizontal position at the bottom third, then **floats
  up and outward** with slight random x-drift, rotation, and scale, fading to 0 opacity over
  ~5s. Stagger start by a few ms each.
- Remove the overlay layer on the last `animationend` (and a safety `setTimeout`).
- Emoji glyph comes from the tile (read its rendered emoji), so EN/PT both work.

### 5.3 Reduced motion

If `window.matchMedia("(prefers-reduced-motion: reduce)").matches`:

- **No burst**. Selection/counts still update (the tile just changes to blue).
- CSS `@media (prefers-reduced-motion: reduce)` also neutralizes the burst animation as a
  belt-and-suspenders.

## 6. Behavior contract (JS, Stimulus `reactions_controller`)

Rewrite the controller around the radio inputs.

- Targets: `input` (the radios), `tile` (labels), `count` (per-tile count), `total` (the Σ),
  `layer` (optional; or create on the fly).
- On `change`/`click` of a radio:
  - Determine `type` from the input value and whether it was already the selected one
    (track `lastSelected`).
  - **Optimistic UI**: update the clicked tile count (+1), decrement the previously selected tile
    (−1) when switching, or −1 and uncheck when clicking the same one (deselect). Recompute `total`.
  - Fire the full-viewport burst on select/switch only (unless reduced motion).
  - `fetch(form_or_path, { method: "POST", headers: { X-CSRF-Token, Accept: text/html,
    Content-Type: x-www-form-urlencoded } })` to `post_reactions_path(post, reaction_type: type)`.
    The server toggles (same type → destroy, different → update, none → create). **Never DELETE.**
  - On fetch failure, roll back counts + checked state to the pre-click snapshot.
- Deselect handling: since native radios can't be unchecked by clicking, intercept
  `mousedown`/`click` on the label of the already-checked radio, `preventDefault`, uncheck it
  programmatically, and run the deselect path.
- All count math uses integers; `total` is the sum of the six counts.

## 7. Accessibility

- Radio family via real `<input type="radio">` → arrow-key navigation, `name` grouping.
- Each tile has an `sr-only` text label (localized): "Like", "Love", "Haha", "Wow", "Sad", "Fire"
  (add `reactions.labels.<type>` to `en.yml`/`pt.yml`).
- `aria-live="polite"` on the total so count changes are announced.
- Focus ring always visible on keyboard focus (`peer-focus-visible`).
- Burst layer is `aria-hidden="true"` and `pointer-events: none`.

## 8. i18n additions

```yaml
reactions:
  like: "👍"        # unchanged (glyph)
  # …
  labels:           # NEW — accessible names
    like:  "Like"   / pt: "Curtir"
    heart: "Love"   / pt: "Amei"
    haha:  "Haha"   / pt: "Haha"
    wow:   "Wow"    / pt: "Uau"
    sad:   "Sad"    / pt: "Triste"
    fire:  "Fire"   / pt: "Incrível"
  total: "%{count} reactions"  / pt: "%{count} reações"   # for aria-live / title
```

## 9. CSS additions (`app/assets/tailwind/application.css`)

- `@keyframes reaction-float` for the burst (translateY up + fade + slight rotate); `.reaction-burst-emoji`
  base (absolute, will-change transform/opacity), `animation: reaction-float 5s ease-out forwards`.
  Per-particle x-drift/rotation/scale set via inline CSS custom properties from JS (`--dx`, `--rot`,
  `--scale`, `--delay`).
- `@media (prefers-reduced-motion: reduce)` → `animation: none` for the burst.

## 10. Acceptance criteria

1. Reactions render as a **flat section** (no boxed card) that sits on the page's default
   background, under the existing top line, with the eyebrow label and a live total count.
2. The six reactions are a **radio family** (`name="reaction"`); exactly one can be selected;
   keyboard arrows move between them; the selected tile is **blue**. Tiles are transparent/bordered.
3. Clicking a reaction turns it blue (no spin); clicking it again clears it.
4. Selecting/switching triggers a **full-viewport emoji burst** of the chosen emoji that floats up
   and fades over ~5s, then cleans itself up (no leftover DOM, no scrollbars introduced).
5. Counts and total update optimistically and persist (verified by reload); failures roll back.
6. With `prefers-reduced-motion: reduce`, no burst, but selection/counts still work.
7. Works in light and dark mode; no horizontal overflow at mobile widths (≥344px).
8. `bin/rails test` (reaction model + controller tests) stays green — backend untouched.

## 11. Verification

- `docker exec … bin/rails test test/models/reaction_test.rb test/controllers/reactions_controller_test.rb`
- Rebuild Tailwind (`bin/rails tailwindcss:build`) and load a post page; react with mouse and
  keyboard; toggle dark mode; emulate reduced motion; check 344px width for overflow.
