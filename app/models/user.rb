class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :reservations, dependent: :destroy

  # Use explicit positional first argument for enum name to avoid Ruby keyword-only
  # argument parsing issues (ensure the required `name` positional arg is provided).
  enum :role, { user: 0, admin: 1 }
  # Basic RFC-like email regex (sufficient for most apps) and validations
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i.freeze
  # Disallow raw HTML tags in free-text fields
  NO_HTML_REGEX = /<[^>]*>/.freeze
  # Strong password: at least 8 chars, one lower, one upper, one digit and one special char
  PASSWORD_FORMAT = /\A(?=.{8,})(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*\W).*\z/.freeze
  # Normalize email to lowercase and validate uniqueness case-insensitively
  before_validation :downcase_email

  validates :name, presence: true, length: { minimum: 2 }, format: { without: NO_HTML_REGEX, message: 'must not contain HTML' }
  validates :phone, format: { without: NO_HTML_REGEX, message: 'must not contain HTML' }, allow_blank: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 },
                    format: { with: EMAIL_REGEX }
  validates :password, presence: true, length: { minimum: 8 }, format: { with: PASSWORD_FORMAT, message: 'must include uppercase, lowercase, digit and special character' }, on: :create
  validates :password, length: { minimum: 8 }, format: { with: PASSWORD_FORMAT, message: 'must include uppercase, lowercase, digit and special character' }, allow_blank: true, on: :update

  # Ensure we never remove the last admin by role change or deletion
  validate :cannot_downgrade_last_admin, if: :will_save_change_to_role?
  before_destroy :prevent_destroying_last_admin

  private

  def downcase_email
    self.email = email.to_s.strip.downcase if email.present?
  end

  def cannot_downgrade_last_admin
    # If previous role was admin and we're changing it away from admin,
    # ensure there's at least one other admin remaining.
    previous = role_was
    # role_was can be stored as string (enum) or integer; normalize to string
    previous = previous.to_s
    return unless previous == 'admin' && role != 'admin'

    other_admins = User.where.not(id: id).where(role: User.roles[:admin]).count
    if other_admins.zero?
      errors.add(:role, 'cannot remove the last admin')
    end
  end

  def prevent_destroying_last_admin
    # If this user is an admin and there are no other admins, prevent destroy
    return unless role == 'admin'

    other_admins = User.where.not(id: id).where(role: User.roles[:admin]).count
    if other_admins.zero?
      errors.add(:base, 'Cannot delete the last admin user')
      throw(:abort)
    end
  end
end
