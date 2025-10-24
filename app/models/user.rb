class User < ApplicationRecord
  has_secure_password

  # Use explicit positional first argument for enum name to avoid Ruby keyword-only
  # argument parsing issues (ensure the required `name` positional arg is provided).
  enum :role, { user: 0, admin: 1 }
  # Basic RFC-like email regex (sufficient for most apps) and validations
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i.freeze

  validates :name,  presence: true, length: { minimum: 2 }
  validates :email, presence: true, uniqueness: true, length: { maximum: 255 },
                    format: { with: EMAIL_REGEX }
  validates :password, presence: true, length: { minimum: 6 }
end
