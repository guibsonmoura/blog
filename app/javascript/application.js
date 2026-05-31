import "@hotwired/turbo-rails"
import "controllers"

// ── Theme ──────────────────────────────────────────────────────────────────

function syncThemeIcons() {
  const isDark = document.documentElement.classList.contains("dark")
  document.querySelectorAll(".sun-icon").forEach(el => el.classList.toggle("hidden", isDark))
  document.querySelectorAll(".moon-icon").forEach(el => el.classList.toggle("hidden", !isDark))
}

function toggleTheme() {
  const html = document.documentElement
  const next = html.classList.contains("dark") ? "light" : "dark"
  html.classList.toggle("dark", next === "dark")
  localStorage.setItem("theme", next)
  syncThemeIcons()
}

// ── Reading progress bar ───────────────────────────────────────────────────

function setupReadingProgress() {
  const bar = document.getElementById("reading-progress-bar")
  if (!bar) return

  function update() {
    const article = document.getElementById("post-article")
    if (!article) return
    const rect  = article.getBoundingClientRect()
    const total = article.offsetHeight - window.innerHeight
    const pct   = total > 0 ? Math.min(100, Math.max(0, (-rect.top / total) * 100)) : 0
    bar.style.width = pct + "%"
  }

  window.addEventListener("scroll", update, { passive: true })
  update()
}

// ── Copy link ──────────────────────────────────────────────────────────────

function setupCopyLinks() {
  document.querySelectorAll("[data-copy-url]").forEach(btn => {
    btn.addEventListener("click", () => {
      navigator.clipboard.writeText(btn.dataset.copyUrl).then(() => {
        const label = btn.querySelector(".copy-label")
        if (label) { label.textContent = "Copied!"; setTimeout(() => { label.textContent = "Copy link" }, 2000) }
      })
    })
  })
}

// ── Search modal ───────────────────────────────────────────────────────────

let searchTimeout = null

function openSearch() {
  const modal = document.getElementById("search-modal")
  if (!modal) return
  modal.classList.remove("hidden")
  document.getElementById("search-input")?.focus()
}

function closeSearch() {
  const modal = document.getElementById("search-modal")
  if (!modal) return
  modal.classList.add("hidden")
  const input = document.getElementById("search-input")
  if (input) input.value = ""
  const results = document.getElementById("search-results")
  if (results) results.innerHTML = '<li class="px-4 py-3 text-sm text-neutral-400" id="search-empty">Type to search…</li>'
}

function renderResults(items) {
  const el = document.getElementById("search-results")
  if (!el) return
  if (!items.length) {
    el.innerHTML = '<li class="px-4 py-3 text-sm text-neutral-400">No results found.</li>'
    return
  }
  el.innerHTML = items.map(item => `
    <li>
      <a href="${item.url}" class="block px-4 py-3 hover:bg-neutral-50 dark:hover:bg-neutral-800">
        <p class="text-sm font-medium text-neutral-950 dark:text-neutral-50">${item.title}</p>
        ${item.excerpt ? `<p class="mt-0.5 text-xs text-neutral-500 dark:text-neutral-400">${item.excerpt}</p>` : ""}
      </a>
    </li>`).join("")
}

function setupSearch() {
  document.querySelector("[data-search-open]")?.addEventListener("click", openSearch)
  document.querySelector("[data-search-backdrop]")?.addEventListener("click", closeSearch)

  document.getElementById("search-input")?.addEventListener("input", e => {
    clearTimeout(searchTimeout)
    const q = e.target.value.trim()
    if (q.length < 2) return
    searchTimeout = setTimeout(() => {
      fetch(`/search?q=${encodeURIComponent(q)}`, { headers: { Accept: "application/json" } })
        .then(r => r.json()).then(renderResults)
    }, 250)
  })
}

document.addEventListener("keydown", e => {
  if ((e.ctrlKey || e.metaKey) && e.key === "k") { e.preventDefault(); openSearch() }
  if (e.key === "Escape") closeSearch()
})

// ── Bootstrap on every Turbo navigation ───────────────────────────────────

document.addEventListener("turbo:load", () => {
  syncThemeIcons()
  document.querySelector("[data-theme-toggle]")?.addEventListener("click", toggleTheme)
  setupReadingProgress()
  setupCopyLinks()
  setupSearch()
})
