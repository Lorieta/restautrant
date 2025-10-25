require "test_helper"

class TimeslotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # create a simple logged-in user for tests
    @user = User.create!(name: "Test User", email: "test@example.com", phone: "111", password: "password", password_confirmation: "password", role: "user")
    @login_params = { session: { email: @user.email, password: "password" } }
    post login_url, params: @login_params
  end

  test "should get index" do
    get timeslots_index_url
    assert_response :success
  end

  test "should get new" do
    get timeslots_new_url
    assert_response :success
  end

  test "should get edit" do
    # create a valid timeslot and request the RESTful edit route
    ts = Timeslot.create!(date: Date.today, start_time: Time.zone.parse("08:00"), end_time: Time.zone.parse("09:00"))
    get edit_timeslot_url(ts)
    assert_response :success
  end
end
