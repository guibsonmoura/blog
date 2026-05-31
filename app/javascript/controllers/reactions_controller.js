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

    // Kept in sync with the active/inactive token sets in _reactions.html.erb.
    const activeClasses = ["border-blue-600", "bg-blue-600", "text-white", "shadow-sm",
      "dark:border-blue-500", "dark:bg-blue-600", "dark:text-white"]
    const inactiveClasses = ["border-neutral-200", "bg-white", "text-neutral-600",
      "hover:border-neutral-300", "dark:border-neutral-800", "dark:bg-neutral-900",
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
