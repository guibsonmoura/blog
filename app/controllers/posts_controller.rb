class PostsController < ApplicationController
  def index
    all_posts = Post.visible.includes(:reactions, :comments)

    # Group by year → month for the archive view
    @archive = all_posts.group_by { |p| p.published_at.year }
                        .transform_values { |posts| posts.group_by { |p| p.published_at.month } }

    @recent_posts   = all_posts.limit(5)
    @archive_counts = all_posts.group_by { |p| p.published_at.strftime("%Y-%m") }
                               .transform_values(&:count)
                               .first(12)
  end

  def show
    @post = Post.visible
                .includes(:reactions, :comments)
                .find_by!(slug: params[:id])
  end
end
