require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "visible returns published posts only" do
    assert_includes Post.visible, posts(:published)
    assert_not_includes Post.visible, posts(:draft)
  end

  test "sets a slug from the title" do
    post = users(:admin).posts.build(
      title: "A Clean Rails Blog",
      excerpt: "Excerpt",
      body_markdown: "Body"
    )

    assert post.valid?
    assert_equal "a-clean-rails-blog", post.slug
  end

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
