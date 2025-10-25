class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      log_in user
      # Redirect based on user role
      if user.admin?
        redirect_to admin_dashboard_path, notice: "Welcome back, #{user.name}!"
      else
        redirect_to user_path(user), notice: "Welcome back, #{user.name}!"
      end
    else
      # Attach errors to a User-like resource so the shared error partial can display them.
      if user
        # Email exists but password incorrect
        user.errors.add(:password, "is incorrect")
        @login_resource = user
      else
        # Email not found — create a temporary user object to hold the error and preserve submitted email
        @login_resource = User.new(email: params.dig(:session, :email))
        @login_resource.errors.add(:email, "User not found")
      end

      # Render the login form with the validation messages available via @login_resource
      render :new
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_path, notice: "Logged out successfully."
  end
end
