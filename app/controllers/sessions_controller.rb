class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      log_in user
      # Handle 'remember me' checkbox
      if params.dig(:session, :remember_me) == "1"
        remember(user)
      else
        forget(user)
      end
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

      # Add a flash alert so a brief message appears in addition to the inline field errors.
      flash.now[:alert] = "Invalid email or password."
      # Render the home page (which now includes the login form) so errors appear inline there.
      # Return 422 so Turbo treats this as a validation/failed form response rather than a full successful HTML response.
      render "application/home", status: :unprocessable_entity
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_path, notice: "Logged out successfully."
  end
end
