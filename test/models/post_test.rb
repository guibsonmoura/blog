require "test_helper"

class PostTest < ActiveSupport::TestCase
  # Helper: build a valid markdown body following the required pattern
  def markdown(title: "My Post", excerpt: "The excerpt.", body: "Content here.")
    "# #{title}\n\n#{excerpt}\n\n---\n\n#{body}"
  end

  # --- Scopes ---

  test "visible returns published posts only" do
    assert_includes Post.visible, posts(:published)
    assert_not_includes Post.visible, posts(:draft)
  end

  test "visible excludes future-published posts" do
    future_post = users(:admin).posts.create!(
      title: "Scheduled Post",
      excerpt: "Coming soon",
      body_markdown: "Body",
      status: :published,
      published_at: 1.day.from_now
    )

    assert_not_includes Post.visible, future_post
  end

  test "recent_first orders by published_at descending" do
    older = users(:admin).posts.create!(
      title: "Older Post", excerpt: "Old", body_markdown: "Old",
      status: :published, published_at: 2.days.ago
    )
    newer = users(:admin).posts.create!(
      title: "Newer Post", excerpt: "New", body_markdown: "New",
      status: :published, published_at: 1.day.ago
    )

    ordered = Post.recent_first.where(id: [ older.id, newer.id ])
    assert_equal newer, ordered.first
    assert_equal older, ordered.last
  end

  # --- extract_from_markdown ---

  test "extracts title from the first h1 heading" do
    post = users(:admin).posts.build(body_markdown: markdown(title: "Hello World"))
    post.valid?

    assert_equal "Hello World", post.title
  end

  test "extracts excerpt from the first paragraph after the title" do
    post = users(:admin).posts.build(body_markdown: markdown(excerpt: "This is the excerpt."))
    post.valid?

    assert_equal "This is the excerpt.", post.excerpt
  end

  test "stops excerpt extraction at the --- separator" do
    md = "# Title\n\nExcerpt line.\n\n---\n\nShould not be in excerpt."
    post = users(:admin).posts.build(body_markdown: md)
    post.valid?

    assert_equal "Excerpt line.", post.excerpt
    assert_not_includes post.excerpt.to_s, "Should not"
  end

  test "joins multi-line excerpt into a single string" do
    md = "# Title\n\nLine one.\nLine two.\n\n---\n\nBody."
    post = users(:admin).posts.build(body_markdown: md)
    post.valid?

    assert_equal "Line one. Line two.", post.excerpt
  end

  test "skips subheadings when looking for excerpt" do
    md = "# Title\n\n## Subtitle\n\nActual excerpt.\n\n---\n\nBody."
    post = users(:admin).posts.build(body_markdown: md)
    post.valid?

    assert_equal "Actual excerpt.", post.excerpt
  end

  test "truncates excerpt at 500 characters" do
    long = "a" * 600
    md = "# Title\n\n#{long}\n\n---\n\nBody."
    post = users(:admin).posts.build(body_markdown: md)
    post.valid?

    assert post.excerpt.length <= 500
  end

  test "does not extract when body_markdown is blank" do
    post = users(:admin).posts.build(title: "Set Manually", excerpt: "Manual", body_markdown: "")
    post.valid?

    assert_equal "Set Manually", post.title
    assert_equal "Manual", post.excerpt
  end

  test "does not overwrite title when markdown has no h1 heading" do
    post = users(:admin).posts.build(
      title: "Manually Set", excerpt: "Manual excerpt", body_markdown: "No heading here."
    )
    post.valid?

    assert_equal "Manually Set", post.title
    assert_equal "Manual excerpt", post.excerpt
  end

  test "slug is derived from the extracted title" do
    post = users(:admin).posts.build(body_markdown: markdown(title: "My New Post"))
    post.valid?

    assert_equal "my-new-post", post.slug
  end

  test "a post with the markdown pattern is valid without explicit title or excerpt" do
    post = users(:admin).posts.build(body_markdown: markdown)

    assert post.valid?, post.errors.full_messages.to_sentence
  end

  test "markdown without h1 heading fails title validation" do
    post = users(:admin).posts.build(body_markdown: "No heading.\n\nJust paragraphs.")

    assert_not post.valid?
    assert post.errors[:title].any?
  end

  test "markdown with title but no excerpt paragraph fails excerpt validation" do
    post = users(:admin).posts.build(body_markdown: "# Title Only\n\n## Skipped heading\n\n---\n\nBody.")

    assert_not post.valid?
    assert post.errors[:excerpt].any?
  end

  test "updating body_markdown re-extracts title and excerpt" do
    post = posts(:published)
    post.update!(body_markdown: markdown(title: "Updated Title", excerpt: "Updated excerpt."))

    assert_equal "Updated Title", post.reload.title
    assert_equal "Updated excerpt.", post.excerpt
  end

  # --- Slug ---

  test "custom slug is preserved when provided alongside a heading" do
    post = users(:admin).posts.build(
      slug: "my-custom-slug",
      body_markdown: markdown(title: "Some Title")
    )

    assert post.valid?
    assert_equal "my-custom-slug", post.slug
  end

  test "to_param returns the slug" do
    assert_equal posts(:published).slug, posts(:published).to_param
  end

  test "slug over 180 characters fails validation" do
    post = users(:admin).posts.build(
      title: "Long Slug", slug: "a" * 181, excerpt: "Excerpt", body_markdown: "Body"
    )

    assert_not post.valid?
    assert post.errors[:slug].any?
  end

  test "duplicate slug fails validation" do
    post = users(:admin).posts.build(
      title: "Dup", slug: posts(:published).slug, excerpt: "Excerpt", body_markdown: "Body"
    )

    assert_not post.valid?
    assert post.errors[:slug].any?
  end

  # --- Presence / length validations ---

  test "blank body_markdown fails validation" do
    post = users(:admin).posts.build(title: "Title", excerpt: "Excerpt", body_markdown: "")

    assert_not post.valid?
    assert post.errors[:body_markdown].any?
  end

  test "title over 160 characters fails validation" do
    post = users(:admin).posts.build(
      title: "a" * 161, excerpt: "Excerpt", body_markdown: "Body"
    )

    assert_not post.valid?
    assert post.errors[:title].any?
  end

  test "excerpt over 500 characters fails validation" do
    post = users(:admin).posts.build(
      title: "Title", excerpt: "a" * 501, body_markdown: "Body"
    )

    assert_not post.valid?
    assert post.errors[:excerpt].any?
  end

  # --- published_at lifecycle ---

  test "published_at is set when post is published" do
    post = users(:admin).posts.create!(
      title: "New Post", excerpt: "Excerpt", body_markdown: "Body", status: :draft
    )

    post.update!(status: :published)

    assert_not_nil post.published_at
    assert post.published_at <= Time.current
  end

  test "published_at is cleared when post is moved back to draft" do
    post = posts(:published)

    post.update!(status: :draft)

    assert_nil post.reload.published_at
  end

  # --- Markdown rendering ---

  test "rendered body sanitizes unsafe html and javascript urls" do
    post = posts(:published)
    post.body_markdown = <<~MARKDOWN
      **Safe**

      <script>alert("x")</script>

      [bad](javascript:alert("x"))
    MARKDOWN

    html = post.rendered_body

    assert_includes html, "<strong>Safe</strong>"
    assert_not_includes html, "<script>"
    assert_not_includes html, "javascript:"
  end
end
