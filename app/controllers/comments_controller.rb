class CommentsController < ApplicationController
  before_action :set_post
  before_action :require_reader!, only: :create

  def create
    @comment = @post.comments.build(comment_params)
    @comment.parent = resolved_parent
    # Identity comes only from the verified OAuth profile — never user input.
    @comment.reader = current_reader
    @comment.author_name = current_reader.name
    @comment.author_email = current_reader.email

    if @comment.save
      redirect_to post_path(@post, anchor: thread_anchor), notice: t("comments.created")
    else
      redirect_to post_path(@post, anchor: "comment-form"),
                  alert: @comment.errors.full_messages.to_sentence
    end
  end

  private

  def set_post
    @post = Post.visible.find_by!(slug: params[:post_id])
  end

  # Only :body is user-supplied; author_name/email/reader/parent are set server-side.
  def comment_params
    params.require(:comment).permit(:body)
  end

  # Resolve the reply target server-side and normalize to one level deep:
  # replying to a reply attaches to that reply's top-level parent.
  def resolved_parent
    parent = @post.comments.find_by(id: params.dig(:comment, :parent_id))
    parent&.parent || parent
  end

  def thread_anchor
    @comment.parent_id ? "comment-#{@comment.parent_id}" : "comments"
  end
end
