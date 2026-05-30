module Admin
  class MarkdownPreviewsController < BaseController
    def create
      render html: MarkdownRenderer.render(params[:body_markdown]), layout: false
    end
  end
end
