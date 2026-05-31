# Guibson Moura Blog - Layout Specification

## Objective

Create a minimalist, fast, and content-focused blog.

The inspiration comes from traditional personal blogs, but the design should have its own identity and not replicate any existing website.

The main goals are:

* Fast loading
* Excellent readability
* Mobile-friendly
* Dark/Light theme toggle
* Search functionality
* RSS feed
* GitHub integration
* Personal "About" page
* Archive organized by year and month

---

# Page Structure

```text
┌─────────────────────────────────────────────┐
│ Guibson Moura Blog                          │
│                                             │
│ Sobre | GitHub | Search | RSS | Theme       │
└─────────────────────────────────────────────┘

                Guibson Moura Blog

          Thoughts about software,
          architecture and technology


2026
 ├── May
 │    ├── Post title
 │    ├── Post title
 │    └── Post title
 │
 ├── April
 │    ├── Post title
 │    └── Post title
 │
 └── March
      ├── Post title
      └── Post title


Sidebar (desktop only)
──────────────────────
• Recent posts
• Categories
• Archive
```

---

# Header

The header should remain visible while scrolling.

Components:

## Blog Name

```html
<h1>Guibson Moura Blog</h1>
```

Clicking returns to homepage.

---

## About

```html
<a href="/about">Sobre</a>
```

Contains:

* Biography
* Professional experience
* Contact links
* Technologies used

---

## GitHub

```html
<a href="https://github.com/guibson">
    GitHub Icon
</a>
```

Opens GitHub profile in new tab.

---

## Search

```html
<input
  type="search"
  placeholder="Search articles..."
>
```

Features:

* Search by title
* Search by tags
* Search by content
* Keyboard shortcut:

```text
Ctrl + K
```

---

## RSS

```html
<a href="/feed.xml">
    RSS Icon
</a>
```

Allows users to subscribe using RSS readers.

---

## Theme Toggle

```html
<button>
    Sun/Moon Icon
</button>
```

Stores preference using:

```javascript
localStorage
```

Supported themes:

* Light
* Dark

---

# Homepage Content

The homepage displays articles grouped by year and month.

Example:

```html
<section>
  <h2>2026</h2>

  <h3>May</h3>

  <ul>
    <li>
      <a href="/posts/my-post">
        My First Post
      </a>
    </li>
  </ul>
</section>
```

Benefits:

* Easy navigation
* Clean organization
* Good for long-term blogs

---

# Improvements Over Traditional Blog Archives

Instead of only showing archives on the sidebar:

Display article excerpts.

Example:

```text
Building a FastAPI Application
A practical guide to production-ready architecture.

Read more →
```

This improves discoverability.

---

# Suggested Layout

Desktop:

```text
┌───────────────────────┬─────────────────────┐
│                       │                     │
│      Articles         │      Sidebar        │
│                       │                     │
│                       │ • Recent posts      │
│                       │ • Archive           │
│                       │ • Tags              │
│                       │                     │
└───────────────────────┴─────────────────────┘
```

Mobile:

```text
┌─────────────────────┐
│     Articles        │
└─────────────────────┘
```

Sidebar becomes collapsible.

---

# Extra Features

Optional enhancements:

## Reading Progress Bar

Shows reading progress while scrolling.

## Estimated Reading Time

Example:

```text
5 min read
```

## Tags

```text
#rails
#flutter
#architecture
#python
```

## Copy Link Button

Allows sharing posts easily.

## Command Palette

```text
Ctrl + K
```

Search posts, tags, and pages.

---

# Design Philosophy

The blog should prioritize:

1. Content first.
2. Fast navigation.
3. Minimal visual noise.
4. Excellent readability.
5. Long-term maintainability.

The goal is not to look modern for the sake of being modern, but to provide a pleasant reading experience that remains timeless.
