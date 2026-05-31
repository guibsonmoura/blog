class ReactionsController < ApplicationController
  before_action :set_post

  def create
    type = params[:reaction_type]
    return head :bad_request unless Reaction.reaction_types.key?(type)

    reaction = @post.reactions.find_by(session_id: session[:reader_id], reaction_type: type)

    if reaction
      reaction.destroy
    else
      @post.reactions.create!(session_id: session[:reader_id], reaction_type: type)
    end

    redirect_to post_path(@post, anchor: "reactions")
  end

  private

  def set_post
    @post = Post.visible.find_by!(slug: params[:post_id])
  end
end
