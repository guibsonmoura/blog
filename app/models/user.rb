class User < ApplicationRecord
  has_many :posts, dependent: :restrict_with_exception

  ARGON2_PREFIX = "$argon2"

  attr_reader :password

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password_digest, presence: true
  validates :password, length: { minimum: 12 }, allow_nil: true

  def password=(raw_password)
    @password = raw_password
    return if raw_password.blank?

    self.password_digest = Argon2::Password.create(raw_password)
  end

  def authenticate(raw_password)
    return false if raw_password.blank? || password_digest.blank? || !argon2_password?

    Argon2::Password.verify_password(raw_password, password_digest) ? self : false
  rescue Argon2::ArgonHashFail
    false
  end

  def argon2_password?
    password_digest.to_s.start_with?(ARGON2_PREFIX)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
