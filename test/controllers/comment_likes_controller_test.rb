require "test_helper"

class CommentLikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:published)
    @reader = readers(:existing_google)
    @comment = @post.comments.create!(reader: @reader, author_name: @reader.name, body: "Hi")
  end

  test "anyone can like a comment anonymously" do
    assert_difference -> { @comment.comment_likes.count }, 1 do
      post comment_like_path(@comment)
    end

    like = @comment.comment_likes.sole
    assert_nil like.reader_id
    assert like.session_id.present?
    assert_redirected_to post_path(@post, anchor: "comment-#{@comment.id}")
  end

  test "liking again toggles the like off" do
    post comment_like_path(@comment)
    assert_difference -> { @comment.comment_likes.count }, -1 do
      post comment_like_path(@comment)
    end
  end

  test "a signed-in reader's like is tied to their account" do
    sign_in_reader(uid: "liker-1")

    assert_difference -> { @comment.comment_likes.count }, 1 do
      post comment_like_path(@comment)
    end

    like = @comment.comment_likes.sole
    assert_equal Reader.find_by(uid: "liker-1").id, like.reader_id
    assert_nil like.session_id
  end

  test "a reply can be liked too" do
    reply = @post.comments.create!(reader: @reader, author_name: @reader.name, body: "A reply", parent: @comment)

    assert_difference -> { reply.comment_likes.count }, 1 do
      post comment_like_path(reply)
    end
  end

  test "an anonymous visitor cannot like the same comment twice" do
    post comment_like_path(@comment)
    post comment_like_path(@comment) # toggles off
    post comment_like_path(@comment) # on again
    assert_equal 1, @comment.comment_likes.count
  end
end
