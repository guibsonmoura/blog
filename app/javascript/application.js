// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

function syncThemeToggleLabel() {
  const toggle = document.querySelector("[data-theme-toggle]")

  if (!toggle) return

  toggle.textContent = document.documentElement.classList.contains("dark") ? "Light" : "Dark"
}

function toggleTheme() {
  const html = document.documentElement
  const nextTheme = html.classList.contains("dark") ? "light" : "dark"

  html.classList.toggle("dark", nextTheme === "dark")
  localStorage.setItem("theme", nextTheme)
  syncThemeToggleLabel()
}

document.addEventListener("turbo:load", () => {
  syncThemeToggleLabel()

  document.querySelector("[data-theme-toggle]")?.addEventListener("click", toggleTheme)
})
