require "test_helper"

class PostTest < ActiveSupport::TestCase
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

  # --- Slug ---

  test "sets a slug from the title" do
    post = users(:admin).posts.build(title: "A Clean Rails Blog", excerpt: "Excerpt", body_markdown: "Body")

    assert post.valid?
    assert_equal "a-clean-rails-blog", post.slug
  end

  test "custom slug is preserved when provided" do
    post = users(:admin).posts.build(
      title: "Some Title", slug: "my-custom-slug", excerpt: "Excerpt", body_markdown: "Body"
    )

    assert post.valid?
    assert_equal "my-custom-slug", post.slug
  end

  test "to_param returns the slug" do
    assert_equal posts(:published).slug, posts(:published).to_param
  end

  test "slug with invalid characters fails validation" do
    post = users(:admin).posts.build(
      title: "Bad Slug", slug: "bad slug!", excerpt: "Excerpt", body_markdown: "Body"
    )

    assert_not post.valid?
    assert post.errors[:slug].any?
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

  test "blank title fails validation" do
    post = users(:admin).posts.build(title: "", excerpt: "Excerpt", body_markdown: "Body")

    assert_not post.valid?
    assert post.errors[:title].any?
  end

  test "title over 160 characters fails validation" do
    post = users(:admin).posts.build(
      title: "a" * 161, excerpt: "Excerpt", body_markdown: "Body"
    )

    assert_not post.valid?
    assert post.errors[:title].any?
  end

  test "blank excerpt fails validation" do
    post = users(:admin).posts.build(title: "Title", excerpt: "", body_markdown: "Body")

    assert_not post.valid?
    assert post.errors[:excerpt].any?
  end

  test "excerpt over 500 characters fails validation" do
    post = users(:admin).posts.build(
      title: "Title", excerpt: "a" * 501, body_markdown: "Body"
    )

    assert_not post.valid?
    assert post.errors[:excerpt].any?
  end

  test "blank body_markdown fails validation" do
    post = users(:admin).posts.build(title: "Title", excerpt: "Excerpt", body_markdown: "")

    assert_not post.valid?
    assert post.errors[:body_markdown].any?
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
