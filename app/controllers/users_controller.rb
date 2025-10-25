class UsersController < ApplicationController
  def home
  end
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    # Do not allow clients to set their role via params (prevents privilege escalation)
    @user.role = "user" unless @user.role.present?
    if @user.save
      log_in @user
      redirect_to root_path, notice: "Welcome, #{@user.name}!"
    else
      render :new
    end
  end

  def show
    @user = User.find(params[:id])
  end

  private

  def user_params
    # Do NOT permit :role here — roles must be assigned server-side only
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
  end
end
