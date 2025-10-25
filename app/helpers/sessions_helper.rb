module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def log_out
    session.delete(:user_id)
    @current_user = nil
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
