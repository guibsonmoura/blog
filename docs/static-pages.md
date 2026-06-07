# Static Pages (Sobre / About)

Pages with content that rarely changes (like the About page) use **locale-specific ERB templates** instead of i18n YAML keys. This avoids runtime lookups and lets Rails compile and cache each template once at boot.

## File convention

Create one file per locale, named `<action>.<locale>.html.erb`. The default file (no locale suffix) is served for Portuguese:

```
app/views/pages/about.pt.html.erb    ← Portuguese
app/views/pages/about.en.html.erb    ← English
app/views/pages/about.html.erb       ← Fallback (kept as PT content)
```

Rails picks the correct template automatically based on `I18n.locale`. No controller changes are needed.

> **Important:** because `config.i18n.default_locale = :en`, Rails falls back to `about.en.html.erb` when a locale-specific file is missing — not to `about.html.erb`. Always create an explicit `<action>.pt.html.erb` file; never rely on the no-suffix file to serve PT content.

## Rules

- **Hardcode the content** directly in the ERB file — no `t()` calls for page body text.
- **Do not add keys** to `config/locales/pt.yml` or `config/locales/en.yml` for this content.
- Keep both files **in sync structurally** (same sections, same markup) so the page looks identical across locales.
- The `page_title` helper at the top of each file should reflect the locale:
  - PT: `<% page_title "Sobre" %>`
  - EN: `<% page_title "About" %>`

## Updating content

To update the About page:

1. Edit `app/views/pages/about.html.erb` with the Portuguese version.
2. Edit `app/views/pages/about.en.html.erb` with the English version.
3. Both files must be updated together — never update one without the other.

## Adding a new static page

1. Create `app/views/pages/<action>.html.erb` (PT) and `app/views/pages/<action>.en.html.erb` (EN).
2. Add a route in `config/routes.rb`: `get "<path>", to: "pages#<action>"`.
3. Add a controller action in `app/controllers/pages_controller.rb` (empty action is fine).
4. Follow the same hardcoded-content pattern — no i18n keys for body text.
