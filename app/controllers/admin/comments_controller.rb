module Admin
  class CommentsController < BaseController
    def destroy
      @comment = Comment.find(params[:id])
      @comment.destroy
      redirect_to admin_post_path(@comment.post), notice: "Comment deleted."
    end
  end
end
