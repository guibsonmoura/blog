class MarkdownRenderer
  ALLOWED_TAGS = %w[
    a blockquote br code del em figcaption figure h1 h2 h3 h4 h5 h6 hr img
    li ol p pre strong table tbody td th thead tr ul
  ].freeze

  ALLOWED_ATTRIBUTES = %w[
    alt href id rel src target title
  ].freeze

  # Heading anchor algorithm: lowercase, spaces→hyphens, keep alphanumeric +
  # accented Latin characters (U+00C0–U+024F covers all Portuguese chars),
  # strip everything else, collapse hyphens.
  def self.heading_anchor(text)
    text.strip
        .downcase
        .gsub(/\s+/, "-")
        .gsub(/[^a-z0-9\-_À-ɏ]/u, "")
        .gsub(/-+/, "-")
        .gsub(/\A-|-\z/, "")
  end

  class << self
    def render(markdown)
      html = renderer.render(markdown.to_s)

      sanitized = ActionController::Base.helpers.sanitize(
        html,
        tags: ALLOWED_TAGS,
        attributes: ALLOWED_ATTRIBUTES
      )

      inject_heading_ids(sanitized)
    end

    private

    def inject_heading_ids(html)
      # Replace Redcarpet/sanitizer-mangled IDs with our own accent-preserving slugs.
      html.gsub(/<(h[1-6])(?:\s[^>]*)?>(.+?)<\/\1>/m) do
        tag   = Regexp.last_match(1)
        inner = Regexp.last_match(2)
        text  = inner.gsub(/<[^>]+>/, "").strip
        id    = MarkdownRenderer.heading_anchor(text)
        "<#{tag} id=\"#{id}\">#{inner}</#{tag}>"
      end
    end

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
