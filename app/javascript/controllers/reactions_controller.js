import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "button", "count"]

  connect() {
    this.formTargets.forEach(form => {
      form.addEventListener("submit", (e) => this.handleSubmit(e, form))
    })
  }

  handleSubmit(e, form) {
    e.preventDefault()

    const btn = form.querySelector("[data-reactions-target='button']")
    const countEl = form.querySelector("[data-reactions-target='count']")
    const active = form.dataset.active === "true"
    const currentCount = parseInt(countEl?.textContent || "0", 10)

    // Optimistic update
    this.setActive(form, btn, !active, active ? currentCount - 1 : currentCount + 1, countEl)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const method = active ? "DELETE" : "POST"

    fetch(form.action, {
      method,
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/html",
        "Content-Type": "application/x-www-form-urlencoded"
      }
    }).catch(() => {
      // Roll back on error
      this.setActive(form, btn, active, currentCount, countEl)
    })
  }

  setActive(form, btn, isActive, count, countEl) {
    form.dataset.active = isActive.toString()
    btn.dataset.active = isActive.toString()
    if (countEl) countEl.textContent = count

    const activeClasses = ["border-blue-400", "bg-blue-50", "text-blue-700",
      "dark:border-blue-700", "dark:bg-blue-950/40", "dark:text-blue-300"]
    const inactiveClasses = ["border-neutral-200", "bg-white", "text-neutral-700",
      "hover:border-neutral-400", "dark:border-neutral-800", "dark:bg-neutral-900",
      "dark:text-neutral-300", "dark:hover:border-neutral-600"]

    if (isActive) {
      btn.classList.remove(...inactiveClasses)
      btn.classList.add(...activeClasses)
    } else {
      btn.classList.remove(...activeClasses)
      btn.classList.add(...inactiveClasses)
    }
  }
}
