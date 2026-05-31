class FeedController < ApplicationController
  def index
    @posts = Post.visible.limit(20)
    respond_to { |f| f.xml }
  end
end
