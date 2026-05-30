class Post < ApplicationRecord
  belongs_to :user

  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy

  enum :status, { draft: 0, published: 1 }, default: :draft

  before_validation :extract_from_markdown, prepend: true
  before_validation :normalize_slug
  before_validation :assign_published_at

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

  private

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
