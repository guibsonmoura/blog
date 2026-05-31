class CommentLikesController < ApplicationController
  include VisitorIdentity

  # Liking a comment is open to anyone (no login required) — anonymous likes
  # use the durable session cookie, signed-in likes belong to the Reader.
  def create
    comment = Comment.find(params[:comment_id])
    like = visitor_record(comment.comment_likes)

    if like
      like.destroy
    else
      comment.comment_likes.create!(visitor_scope)
    end

    redirect_to post_path(comment.post, anchor: "comment-#{comment.id}")
  end
end
