require "test_helper"

class ReactionTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published)
    @reader = readers(:existing_google)
  end

  test "requires a reader or a session" do
    reaction = Reaction.new(post: @post, reaction_type: :like)
    assert_not reaction.valid?
    assert_includes reaction.errors[:base], "must belong to a reader or a session"
  end

  test "is valid with only a session_id (anonymous)" do
    assert Reaction.new(post: @post, session_id: "anon-uuid", reaction_type: :like).valid?
  end

  test "is valid with only a reader (logged in)" do
    assert Reaction.new(post: @post, reader: @reader, reaction_type: :heart).valid?
  end

  test "a reader may hold only one reaction per post" do
    @post.reactions.create!(reader: @reader, reaction_type: :like)
    second = @post.reactions.build(reader: @reader, reaction_type: :heart)
    assert_not second.valid?
  end

  test "a session may hold only one reaction per post" do
    @post.reactions.create!(session_id: "anon-uuid", reaction_type: :like)
    second = @post.reactions.build(session_id: "anon-uuid", reaction_type: :heart)
    assert_not second.valid?
  end

  test "the same session may react on different posts" do
    other = users(:admin).posts.create!(
      title: "Another", excerpt: "x", body_markdown: "y", status: :published, published_at: 1.day.ago
    )
    @post.reactions.create!(session_id: "anon-uuid", reaction_type: :like)
    assert other.reactions.build(session_id: "anon-uuid", reaction_type: :like).valid?
  end
end
