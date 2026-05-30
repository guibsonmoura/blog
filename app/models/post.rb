class Post < ApplicationRecord
  belongs_to :user

  has_one_attached :cover_image

  enum :status, { draft: 0, published: 1 }, default: :draft

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
  validate :cover_image_type_and_size

  def to_param
    slug
  end

  def rendered_body
    MarkdownRenderer.render(body_markdown)
  end

  private

  def normalize_slug
    source = slug.presence || title
    self.slug = source.to_s.parameterize
  end

  def assign_published_at
    self.published_at ||= Time.current if published?
    self.published_at = nil if draft?
  end

  def cover_image_type_and_size
    return unless cover_image.attached?

    unless cover_image.content_type.in?(%w[image/png image/jpeg image/webp image/gif])
      errors.add(:cover_image, "must be a PNG, JPG, WebP, or GIF")
    end

    if cover_image.byte_size > 5.megabytes
      errors.add(:cover_image, "must be smaller than 5 MB")
    end
  end
end
