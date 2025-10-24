require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user_params = { name: "Test User", email: "test@example.com", phone: "12345", password: "password", password_confirmation: "password", role: "user" }
    @new_user_instance = User.new(@user_params)
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post users_url, params: { user: @user_params }
    end

    created = User.find_by(email: @user_params[:email])
    assert_not_nil created
    assert_equal @new_user_instance.name, created.name

    assert_redirected_to root_url
  end

  test "should get show" do
    user = users(:one)
    get user_url(user)
    assert_response :success
  end
end
