class Reaction < ApplicationRecord
  belongs_to :post
  # Logged-in readers own their reaction; anonymous reactions carry only a
  # durable session_id and no reader.
  belongs_to :reader, optional: true

  enum :reaction_type, { like: 0, heart: 1, haha: 2, wow: 3, sad: 4, fire: 5 }

  validate :reader_or_session_present

  # One reaction per identity per post (mirrors the partial unique indexes).
  validates :reader_id, uniqueness: { scope: :post_id }, if: -> { reader_id.present? }
  validates :session_id, uniqueness: { scope: :post_id }, if: -> { reader_id.blank? }

  private

  def reader_or_session_present
    return if reader_id.present? || session_id.present?

    errors.add(:base, "must belong to a reader or a session")
  end
end
