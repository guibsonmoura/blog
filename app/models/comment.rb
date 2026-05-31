class Comment < ApplicationRecord
  belongs_to :post
  # Optional/nullable: legacy anonymous comments have no reader.
  belongs_to :reader, optional: true

  # One-level threading: replies point at a top-level comment.
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  has_many :comment_likes, dependent: :destroy

  scope :top_level, -> { where(parent_id: nil) }

  validates :author_name, presence: true
  validates :body, presence: true, length: { maximum: 2000 }
  validate :parent_must_be_top_level_in_same_post

  private

  def parent_must_be_top_level_in_same_post
    return if parent.blank?

    errors.add(:parent, "must belong to the same post") if parent.post_id != post_id
    errors.add(:parent, "cannot be a reply") if parent.parent_id.present?
  end
end
