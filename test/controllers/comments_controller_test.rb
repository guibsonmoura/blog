require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup { @post = posts(:published) }

  test "anonymous visitors cannot comment" do
    assert_no_difference -> { @post.comments.count } do
      post post_comments_path(@post), params: { comment: { body: "Sneaky anonymous comment" } }
    end

    assert_redirected_to post_path(@post, anchor: "comment-form")
    assert_equal I18n.t("auth.sign_in_required"), flash[:alert]
  end

  test "signed-in readers can comment with identity from their profile" do
    sign_in_reader(uid: "commenter-1", email: "author@example.com", name: "Profile Name")

    assert_difference -> { @post.comments.count }, 1 do
      post post_comments_path(@post), params: { comment: { body: "A real comment" } }
    end

    assert_redirected_to post_path(@post, anchor: "comments")
    comment = @post.comments.order(:created_at).last
    assert_equal "A real comment", comment.body
    assert_equal "Profile Name", comment.author_name
    assert_equal "author@example.com", comment.author_email
    assert_equal Reader.find_by(uid: "commenter-1"), comment.reader
  end

  test "author identity cannot be spoofed via params" do
    sign_in_reader(uid: "commenter-2", email: "trusted@example.com", name: "Trusted Name")

    post post_comments_path(@post),
         params: { comment: { body: "Hi", author_name: "Spoofed", author_email: "evil@example.com" } }

    comment = @post.comments.order(:created_at).last
    assert_equal "Trusted Name", comment.author_name
    assert_equal "trusted@example.com", comment.author_email
  end

  test "blank body is rejected" do
    sign_in_reader(uid: "commenter-3")

    assert_no_difference -> { @post.comments.count } do
      post post_comments_path(@post), params: { comment: { body: "" } }
    end

    assert_redirected_to post_path(@post, anchor: "comment-form")
  end

  test "a signed-in reader can reply to a comment" do
    parent = @post.comments.create!(author_name: "X", body: "Top")
    sign_in_reader(uid: "replier-1")

    post post_comments_path(@post), params: { comment: { body: "My reply", parent_id: parent.id } }

    reply = @post.comments.order(:created_at).last
    assert_equal parent.id, reply.parent_id
    assert_redirected_to post_path(@post, anchor: "comment-#{parent.id}")
  end

  test "anonymous visitors cannot reply" do
    parent = @post.comments.create!(author_name: "X", body: "Top")

    assert_no_difference -> { @post.comments.count } do
      post post_comments_path(@post), params: { comment: { body: "Sneaky", parent_id: parent.id } }
    end
    assert_equal I18n.t("auth.sign_in_required"), flash[:alert]
  end

  test "replying to a reply flattens to the top-level parent" do
    parent = @post.comments.create!(author_name: "X", body: "Top")
    reply = @post.comments.create!(author_name: "Y", body: "Reply", parent: parent)
    sign_in_reader(uid: "replier-2")

    post post_comments_path(@post), params: { comment: { body: "Nested", parent_id: reply.id } }

    assert_equal parent.id, @post.comments.order(:created_at).last.parent_id
  end

  test "a parent_id from another post is ignored (becomes top-level)" do
    other = users(:admin).posts.create!(
      title: "Other", excerpt: "x", body_markdown: "y", status: :published, published_at: 1.day.ago
    )
    foreign = other.comments.create!(author_name: "Z", body: "Foreign")
    sign_in_reader(uid: "replier-3")

    post post_comments_path(@post), params: { comment: { body: "Hi", parent_id: foreign.id } }

    assert_nil @post.comments.order(:created_at).last.parent_id
  end
end
