class PostsController < ApplicationController
  POSTS_PER_PAGE = 6

  def index
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    posts = Post.visible.includes(:user, :reactions, :comments, cover_image_attachment: :blob)

    @total_pages = (posts.count.to_f / POSTS_PER_PAGE).ceil
    @posts = posts.limit(POSTS_PER_PAGE).offset((@page - 1) * POSTS_PER_PAGE)
  end

  def show
    @post = Post.visible
                .includes(:user, :reactions, comments: [], cover_image_attachment: :blob)
                .find_by!(slug: params[:id])
  end
end
