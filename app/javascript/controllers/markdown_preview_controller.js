import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "preview", "source", "uploadStatus"]
  static values = { uploadUrl: String, url: String }

  connect() {
    this.queuePreview()
  }

  queuePreview() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.preview(), 250)
  }

  preview() {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const body = new URLSearchParams({ body_markdown: this.sourceTarget.value })

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        Accept: "text/html",
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": token
      },
      body
    })
      .then((response) => response.ok ? response.text() : "")
      .then((html) => {
        this.previewTarget.innerHTML = html
      })
  }

  uploadImage(event) {
    const file = event.target.files[0]

    if (!file) return

    const token = document.querySelector("meta[name='csrf-token']")?.content
    const body = new FormData()
    body.append("image", file)
    this.setUploadStatus("Uploading...")

    fetch(this.uploadUrlValue, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": token
      },
      body
    })
      .then(async (response) => {
        const payload = await response.json()
        if (!response.ok) throw new Error(payload.error || "Upload failed.")
        return payload
      })
      .then((payload) => {
        this.insertAtCursor(payload.markdown)
        this.setUploadStatus("Uploaded.")
        this.queuePreview()
      })
      .catch((error) => {
        this.setUploadStatus(error.message)
      })
      .finally(() => {
        event.target.value = ""
      })
  }

  insertAtCursor(text) {
    const field = this.sourceTarget
    const start = field.selectionStart
    const end = field.selectionEnd
    const prefix = field.value.substring(0, start)
    const suffix = field.value.substring(end)
    const insertion = `${text}\n`

    field.value = `${prefix}${insertion}${suffix}`
    field.focus()
    field.setSelectionRange(start + insertion.length, start + insertion.length)
  }

  setUploadStatus(message) {
    if (this.hasUploadStatusTarget) {
      this.uploadStatusTarget.textContent = message
    }
  }
}
