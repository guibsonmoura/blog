class ReactionsController < ApplicationController
  include VisitorIdentity

  before_action :set_post

  # A visitor has at most one reaction per post (single choice):
  #   - clicking the active reaction removes it,
  #   - clicking a different one switches to it,
  #   - otherwise a new reaction is created.
  def create
    type = params[:reaction_type]
    return head :bad_request unless Reaction.reaction_types.key?(type)

    reaction = visitor_record(@post.reactions)

    if reaction&.reaction_type == type
      reaction.destroy
    elsif reaction
      reaction.update!(reaction_type: type)
    else
      claim_anonymous_reaction if reader_signed_in?
      @post.reactions.create!(visitor_scope.merge(reaction_type: type))
    end

    redirect_to post_path(@post, anchor: "reactions")
  end

  private

  def set_post
    @post = Post.visible.find_by!(slug: params[:post_id])
  end

  # Prevent the same browser from double-counting: when a logged-in reader
  # reacts, drop any anonymous reaction they left on this post before signing in.
  def claim_anonymous_reaction
    @post.reactions.where(reader_id: nil, session_id: reader_id).delete_all
  end
end
