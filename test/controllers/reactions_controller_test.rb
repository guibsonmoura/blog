require "test_helper"

class ReactionsControllerTest < ActionDispatch::IntegrationTest
  setup { @post = posts(:published) }

  def react(type)
    post post_reactions_path(@post, reaction_type: type)
  end

  test "anonymous reaction is stored against a durable session, not a reader" do
    assert_difference -> { @post.reactions.count }, 1 do
      react(:like)
    end

    reaction = @post.reactions.sole
    assert_nil reaction.reader_id
    assert reaction.session_id.present?
    assert_equal "like", reaction.reaction_type
  end

  test "anonymous reaction persists across requests (safe forever)" do
    react(:like)
    # A later request from the same browser (cookie jar) sees the reaction
    # still there and does not create a duplicate.
    get post_path(@post)
    assert_equal 1, @post.reactions.count
  end

  test "clicking a different reaction switches the single choice" do
    react(:like)
    assert_no_difference -> { @post.reactions.count } do
      react(:heart)
    end
    assert_equal "heart", @post.reactions.sole.reaction_type
  end

  test "clicking the active reaction removes it" do
    react(:like)
    assert_difference -> { @post.reactions.count }, -1 do
      react(:like)
    end
  end

  test "rejects an unknown reaction type" do
    assert_no_difference -> { @post.reactions.count } do
      react(:thumbsdown)
    end
    assert_response :bad_request
  end

  test "a signed-in reader's reaction is tied to their account" do
    sign_in_reader(uid: "reactor-1")

    assert_difference -> { @post.reactions.count }, 1 do
      react(:fire)
    end

    reaction = @post.reactions.sole
    assert_equal Reader.find_by(uid: "reactor-1").id, reaction.reader_id
    assert_nil reaction.session_id
  end

  test "a signed-in reader holds only one reaction per post" do
    sign_in_reader(uid: "reactor-2")
    react(:like)
    react(:wow)
    assert_equal 1, @post.reactions.count
    assert_equal "wow", @post.reactions.sole.reaction_type
  end

  test "signing in claims the anonymous reaction so it isn't double counted" do
    react(:like)                 # anonymous, same browser/cookie jar
    assert_equal 1, @post.reactions.count

    sign_in_reader(uid: "reactor-3")
    react(:heart)                # now logged in, same cookie

    assert_equal 1, @post.reactions.count, "anonymous reaction should have been claimed"
    reaction = @post.reactions.sole
    assert_equal Reader.find_by(uid: "reactor-3").id, reaction.reader_id
    assert_equal "heart", reaction.reaction_type
  end
end
