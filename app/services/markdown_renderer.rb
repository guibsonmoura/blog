class MarkdownRenderer
  ALLOWED_TAGS = %w[
    a blockquote br code del em figcaption figure h1 h2 h3 h4 h5 h6 hr img
    li ol p pre strong table tbody td th thead tr ul
  ].freeze

  ALLOWED_ATTRIBUTES = %w[
    alt href id rel src target title
  ].freeze

  class << self
    def render(markdown)
      html = renderer.render(markdown.to_s)

      ActionController::Base.helpers.sanitize(
        html,
        tags: ALLOWED_TAGS,
        attributes: ALLOWED_ATTRIBUTES
      )
    end

    private

    def renderer
      @renderer ||= begin
        html_renderer = Redcarpet::Render::HTML.new(
          filter_html: false,
          hard_wrap: true,
          with_toc_data: true,
          link_attributes: { rel: "nofollow noopener", target: "_blank" }
        )

        Redcarpet::Markdown.new(
          html_renderer,
          autolink: true,
          fenced_code_blocks: true,
          no_intra_emphasis: true,
          strikethrough: true,
          tables: true
        )
      end
    end
  end
end
