require "test_helper"

class CommentLikeTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published)
    @reader = readers(:existing_google)
    @comment = @post.comments.create!(reader: @reader, author_name: @reader.name, body: "Hi")
  end

  test "requires a reader or a session" do
    like = CommentLike.new(comment: @comment)
    assert_not like.valid?
    assert_includes like.errors[:base], "must belong to a reader or a session"
  end

  test "is valid with only a session_id (anonymous)" do
    assert CommentLike.new(comment: @comment, session_id: "anon-uuid").valid?
  end

  test "is valid with only a reader" do
    assert CommentLike.new(comment: @comment, reader: @reader).valid?
  end

  test "one like per session per comment" do
    @comment.comment_likes.create!(session_id: "anon-uuid")
    assert_not @comment.comment_likes.build(session_id: "anon-uuid").valid?
  end

  test "one like per reader per comment" do
    @comment.comment_likes.create!(reader: @reader)
    assert_not @comment.comment_likes.build(reader: @reader).valid?
  end
end
