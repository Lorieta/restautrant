require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "name must not contain HTML tags" do
    u = User.new(name: "<b>bad</b>", email: "user_html@example.com", password: "Password1!", password_confirmation: "Password1!")
    assert_not u.valid?
    assert_includes u.errors[:name], 'must not contain HTML'
  end

  test "password complexity is enforced" do
    weak = User.new(name: "Weak", email: "weak@example.com", password: "weakpass", password_confirmation: "weakpass")
    assert_not weak.valid?
    assert_includes weak.errors[:password], 'must include uppercase, lowercase, digit and special character'

    strong = User.new(name: "Strong", email: "strong@example.com", password: "Str0ng!Pass", password_confirmation: "Str0ng!Pass")
    assert strong.valid?
  end
end
