class CommentLike < ApplicationRecord
  belongs_to :comment
  # Logged-in readers own their like; anonymous likes carry only a durable
  # session_id and no reader.
  belongs_to :reader, optional: true

  validate :reader_or_session_present

  # One like per identity per comment (mirrors the partial unique indexes).
  validates :reader_id, uniqueness: { scope: :comment_id }, if: -> { reader_id.present? }
  validates :session_id, uniqueness: { scope: :comment_id }, if: -> { reader_id.blank? }

  private

  def reader_or_session_present
    return if reader_id.present? || session_id.present?

    errors.add(:base, "must belong to a reader or a session")
  end
end
