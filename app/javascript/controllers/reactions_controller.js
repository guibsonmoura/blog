import { Controller } from "@hotwired/stimulus"

// Radio-family reactions card. Single choice per visitor:
//   - click an unselected reaction  -> select (count +1, spin + burst)
//   - click a different reaction     -> switch (old -1, new +1, spin + burst)
//   - click the selected reaction    -> clear  (count -1, spin, no burst)
// The server (`POST /posts/:id/reactions`) performs the same toggle; the UI
// updates optimistically and rolls back on failure. See specs/reactions-card.md.
export default class extends Controller {
  static targets = ["input", "tile", "emoji", "count", "total"]

  connect() {
    this.reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.selected = this.inputTargets.find((i) => i.checked)?.dataset.reactionType || null
    this.onClick = this.onClick.bind(this)
    this.inputTargets.forEach((input) => input.addEventListener("click", this.onClick))
  }

  disconnect() {
    this.inputTargets.forEach((input) => input.removeEventListener("click", this.onClick))
  }

  onClick(event) {
    const input = event.currentTarget
    const type = input.dataset.reactionType
    const wasSelected = this.selected === type
    const snapshot = this.snapshot()

    if (wasSelected) {
      // Native radios can't be unchecked by clicking — clear it ourselves.
      input.checked = false
      this.bump(type, -1)
      this.selected = null
      this.spin(type)
    } else {
      if (this.selected) this.bump(this.selected, -1)
      this.bump(type, +1)
      this.selected = type
      this.spin(type)
      this.burst(input, type)
    }

    this.updateTotal()
    this.persist(input.dataset.reactionUrl, snapshot)
  }

  // --- optimistic state -----------------------------------------------------

  indexOf(type) {
    return this.inputTargets.findIndex((i) => i.dataset.reactionType === type)
  }

  bump(type, delta) {
    const el = this.countTargets[this.indexOf(type)]
    if (el) el.textContent = Math.max(0, parseInt(el.textContent || "0", 10) + delta)
  }

  updateTotal() {
    const total = this.countTargets.reduce(
      (sum, el) => sum + (parseInt(el.textContent || "0", 10) || 0),
      0
    )
    const t = this.totalTarget
    const template = (total === 1 ? t.dataset.one : t.dataset.other) || "%{count}"
    t.textContent = template.replace("%{count}", total)
  }

  snapshot() {
    return {
      counts: this.countTargets.map((el) => el.textContent),
      checked: this.inputTargets.map((i) => i.checked),
      selected: this.selected,
      total: this.totalTarget.textContent,
    }
  }

  rollback(snap) {
    snap.counts.forEach((v, i) => (this.countTargets[i].textContent = v))
    snap.checked.forEach((v, i) => (this.inputTargets[i].checked = v))
    this.selected = snap.selected
    this.totalTarget.textContent = snap.total
  }

  // --- server ---------------------------------------------------------------

  persist(url, snapshot) {
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrf,
        Accept: "text/html",
        "Content-Type": "application/x-www-form-urlencoded",
      },
    })
      .then((res) => {
        if (!res.ok) this.rollback(snapshot)
      })
      .catch(() => this.rollback(snapshot))
  }

  // --- motion ----------------------------------------------------------------

  spin(type) {
    if (this.reduceMotion) return
    const emoji = this.emojiTargets[this.indexOf(type)]
    if (!emoji) return
    emoji.classList.remove("reaction-spin")
    // force reflow so the animation can re-trigger on rapid clicks
    void emoji.offsetWidth
    emoji.classList.add("reaction-spin")
    emoji.addEventListener("animationend", () => emoji.classList.remove("reaction-spin"), {
      once: true,
    })
  }

  burst(input, type) {
    if (this.reduceMotion) return
    const glyph = this.emojiTargets[this.indexOf(type)]?.textContent.trim()
    if (!glyph) return

    const rect = input.getBoundingClientRect()
    const originX = rect.left + rect.width / 2

    const layer = document.createElement("div")
    layer.className = "reaction-burst"
    layer.setAttribute("aria-hidden", "true")

    const count = 20
    let remaining = count
    for (let i = 0; i < count; i++) {
      const span = document.createElement("span")
      span.className = "reaction-burst-emoji"
      span.textContent = glyph
      // deterministic spread so particles fan out left/right and vary in size
      const spread = (i / (count - 1) - 0.5) * 2 // -1 .. 1
      const dx = spread * (120 + (i % 5) * 40)
      const rot = spread * 90 + (i % 3) * 30
      const scale = 0.7 + (i % 4) * 0.18
      span.style.left = `${originX}px`
      span.style.setProperty("--dx", `${dx}px`)
      span.style.setProperty("--rot", `${rot}deg`)
      span.style.setProperty("--scale", scale.toString())
      span.style.setProperty("--delay", `${(i % 6) * 35}ms`)
      span.addEventListener("animationend", () => {
        if (--remaining === 0) layer.remove()
      })
      layer.appendChild(span)
    }

    document.body.appendChild(layer)
    // Safety net in case animationend doesn't fire (e.g. tab hidden).
    // Must outlast the 5s float + max stagger delay.
    setTimeout(() => layer.remove(), 6000)
  }
}
