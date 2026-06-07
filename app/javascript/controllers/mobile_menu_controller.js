import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "openIcon", "closeIcon"]

  connect() {
    this._onNavigate = () => this.close()
    document.addEventListener("turbo:navigate", this._onNavigate)
  }

  disconnect() {
    document.removeEventListener("turbo:navigate", this._onNavigate)
    this._restoreScroll()
  }

  toggle() {
    this.panelTarget.classList.contains("hidden") ? this.open() : this.close()
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.openIconTarget.classList.add("hidden")
    this.closeIconTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
    this._restoreScroll()
  }

  _restoreScroll() {
    document.body.style.overflow = ""
  }
}
