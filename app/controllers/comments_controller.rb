class CommentsController < ApplicationController
  def create
    @post = Post.visible.find_by!(slug: params[:post_id])
    @comment = @post.comments.build(comment_params)

    if @comment.save
      redirect_to post_path(@post, anchor: "comments"), notice: t("comments.created")
    else
      redirect_to post_path(@post, anchor: "comment-form"),
                  alert: @comment.errors.full_messages.to_sentence
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:author_name, :author_email, :body)
  end
end
