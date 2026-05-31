class SearchController < ApplicationController
  def index
    query = params[:q].to_s.strip
    @results = query.length >= 2 ? Post.visible.search(query).limit(20) : []
    respond_to do |f|
      f.html
      f.json { render json: @results.map { |p| { title: p.localized_title, url: post_path(p), excerpt: p.localized_excerpt&.truncate(100) } } }
    end
  end
end
