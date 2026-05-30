module Admin
  class PostsController < BaseController
    before_action :set_post, only: [ :show, :edit, :update, :destroy ]

    def index
      @posts = Post.includes(:user).order(created_at: :desc)
    end

    def show
    end

    def new
      @post = current_admin.posts.build(status: :draft)
    end

    def create
      @post = current_admin.posts.build(post_params)

      if @post.save
        redirect_to admin_post_path(@post), notice: "Post created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @post.update(post_params)
        @post.cover_image.purge_later if remove_cover_image? && params.dig(:post, :cover_image).blank?
        redirect_to admin_post_path(@post), notice: "Post updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "Post deleted."
    end

    private

    def set_post
      @post = Post.find_by!(slug: params[:id])
    end

    def post_params
      params.require(:post).permit(
        :title,
        :slug,
        :excerpt,
        :body_markdown,
        :status,
        :published_at,
        :cover_image
      )
    end

    def remove_cover_image?
      params.dig(:post, :remove_cover_image) == "1"
    end
  end
end
