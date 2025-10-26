module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end

  def current_user
    # First try session
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      # Fall back to persistent cookie
      user = User.find_by(id: user_id)
      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in(user)
        @current_user = user
      end
    end
    @current_user
  end

  def logged_in?
    current_user.present?
  end

  def log_out
    session.delete(:user_id)
    @current_user = nil
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # Remember a user in a persistent cookie
  def remember(user)
    user.remember
    cookies.signed[:user_id] = { value: user.id, expires: 20.years.from_now }
    cookies[:remember_token] = { value: user.remember_token, expires: 20.years.from_now }
  end

  # Forget a persistent session
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # Require any logged-in user
  def require_login
    return if logged_in?

    flash[:alert] = "Please log in to continue."
    redirect_to login_path
  end

  # Require admin privileges
  def require_admin
    unless logged_in? && current_user.admin?
      flash[:alert] = "You are not authorized to access this page."
      redirect_to root_path
    end
  end
end
