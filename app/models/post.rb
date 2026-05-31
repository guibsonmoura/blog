class Post < ApplicationRecord
  belongs_to :user

  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy

  enum :status, { draft: 0, published: 1 }, default: :draft

  before_validation :extract_from_markdown, prepend: true
  before_validation :normalize_slug
  before_validation :assign_published_at
  after_save :enqueue_translation, if: :saved_change_to_status?

  scope :recent_first, -> { order(published_at: :desc, created_at: :desc) }
  scope :visible, -> { published.where("published_at <= ?", Time.current).recent_first }

  validates :title, presence: true, length: { maximum: 160 }
  validates :slug, presence: true,
                   uniqueness: true,
                   length: { maximum: 180 },
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :excerpt, presence: true, length: { maximum: 500 }
  validates :body_markdown, presence: true

  def to_param
    slug
  end

  def rendered_body
    MarkdownRenderer.render(body_markdown)
  end

  def localized_title
    I18n.locale == :pt || title_en.blank? ? title : title_en
  end

  def localized_excerpt
    I18n.locale == :pt || excerpt_en.blank? ? excerpt : excerpt_en
  end

  def localized_body
    source = I18n.locale == :pt || body_markdown_en.blank? ? body_markdown : body_markdown_en
    MarkdownRenderer.render(strip_header(source))
  end

  def toc_items
    source = I18n.locale == :pt || body_markdown_en.blank? ? body_markdown : body_markdown_en
    strip_header(source).lines.filter_map do |line|
      if (m = line.match(/\A(##|###)\s+(.+)/))
        { level: m[1].length, text: m[2].strip, anchor: heading_anchor(m[2].strip) }
      end
    end
  end

  def body_content
    strip_header(body_markdown)
  end

  private

def heading_anchor(text)
  # Matches Redcarpet with_toc_data: non-ASCII bytes become "-", then collapse.
  text.downcase
      .gsub(/[^a-z0-9_ -]/) { |c| c.ord > 127 ? "-" : "" }
      .gsub(/ +/, "-")
      .gsub(/-+/, "-")
      .strip
end

  def strip_header(markdown)
    return "" if markdown.blank?

    lines = markdown.lines

    # If a --- separator exists, everything after it is the body
    separator_index = lines.index { |l| l.strip == "---" }
    return lines.drop(separator_index + 1).join.lstrip if separator_index

    # No separator: skip the leading # heading and the first paragraph (excerpt)
    after_title = lines.drop_while { |l| l.match?(/\A#\s+/) || l.strip.empty? }
    after_excerpt = after_title.drop_while { |l| l.strip.present? }
    after_excerpt.drop_while { |l| l.strip.empty? }.join.lstrip
  end

  def enqueue_translation
    TranslatePostJob.perform_later(id) if published?
  end

  def extract_from_markdown
    return if body_markdown.blank?

    lines = body_markdown.strip.lines
    title_line = lines.find { |l| l.match?(/\A#\s+\S/) }
    return unless title_line

    self.title = title_line.sub(/\A#\s+/, "").strip

    rest = lines.drop(lines.index(title_line) + 1)
    para = []
    rest.each do |line|
      break if line.strip == "---"
      next  if line.strip.empty? && para.empty?
      break if line.strip.empty? && para.any?
      next  if line.match?(/\A#+\s/)
      para << line.strip
    end
    self.excerpt = para.join(" ").strip.truncate(500) if para.any?
  end

  def normalize_slug
    source = slug.presence || title
    self.slug = source.to_s.parameterize
  end

  def assign_published_at
    self.published_at ||= Time.current if published?
    self.published_at = nil if draft?
  end
end
