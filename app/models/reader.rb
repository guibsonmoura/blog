class Reader < ApplicationRecord
  # Nullify rather than destroy so a deleted reader's comments remain (they fall
  # back to the stored author_name in the view).
  has_many :comments, dependent: :nullify

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  # Find or create a Reader from an OmniAuth auth hash, refreshing the cached
  # profile fields. Tolerant of providers that omit name/email (the controller
  # is the only writer of these values, all sourced from the verified profile).
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |reader|
      info = auth.info || {}
      reader.email = info.email.presence || reader.email

      # OmniAuth's InfoHash#name falls back to the email when no real name is
      # present — treat that as "no name" so we show a friendlier local-part.
      name = info.name.presence
      name = nil if name.present? && name == info.email
      reader.name = name || reader.name || reader.email&.split("@")&.first || "Reader"

      reader.avatar_url = info.image.presence || reader.avatar_url
      reader.save!
    end
  end
end
