require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Create a real user to use when we need a logged-in session in tests
    @session_user = User.create!(name: "Session User", email: "session@example.com", phone: "000", password: "password", password_confirmation: "password", role: "user")
    @session_params = { session: { email: @session_user.email, password: "password" } }
  end
  test "should get new" do
    get login_url
    assert_response :success
  end

  test "should get create" do
    # Post with invalid credentials — controller will render :new (200)
    post login_url, params: { session: { email: "noone@example.com", password: "wrong" } }
    assert_response :success
  end

  test "should get destroy" do
    # Log in first to establish a session, then delete to log out
    post login_url, params: @session_params
    delete logout_url
    assert_redirected_to root_url
  end
end
