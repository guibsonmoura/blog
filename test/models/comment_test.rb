require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published)
    @reader = readers(:existing_google)
  end

  def top_level(body: "Top level")
    @post.comments.create!(reader: @reader, author_name: @reader.name, body: body)
  end

  test "a reply attaches to a top-level comment" do
    parent = top_level
    reply = @post.comments.create!(reader: @reader, author_name: @reader.name, body: "A reply", parent: parent)

    assert_equal parent, reply.parent
    assert_includes parent.replies, reply
    assert_equal [ parent ], @post.comments.top_level.to_a
  end

  test "a comment whose parent is itself a reply is invalid (one level only)" do
    parent = top_level
    reply = @post.comments.create!(reader: @reader, author_name: @reader.name, body: "A reply", parent: parent)

    nested = @post.comments.build(reader: @reader, author_name: @reader.name, body: "Nested", parent: reply)
    assert_not nested.valid?
    assert_includes nested.errors[:parent], "cannot be a reply"
  end

  test "parent must belong to the same post" do
    other_post = users(:admin).posts.create!(
      title: "Other", excerpt: "x", body_markdown: "y", status: :published, published_at: 1.day.ago
    )
    foreign_parent = other_post.comments.create!(reader: @reader, author_name: @reader.name, body: "Foreign")

    reply = @post.comments.build(reader: @reader, author_name: @reader.name, body: "Reply", parent: foreign_parent)
    assert_not reply.valid?
    assert_includes reply.errors[:parent], "must belong to the same post"
  end

  test "destroying a parent destroys its replies and their likes" do
    parent = top_level
    reply = @post.comments.create!(reader: @reader, author_name: @reader.name, body: "A reply", parent: parent)
    reply.comment_likes.create!(session_id: "anon")
    parent.comment_likes.create!(session_id: "anon")

    assert_difference -> { Comment.count } => -2, -> { CommentLike.count } => -2 do
      parent.destroy
    end
  end
end
