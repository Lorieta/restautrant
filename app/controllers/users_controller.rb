class UsersController < ApplicationController
  before_action :require_admin, only: [:admin, :index]
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :require_same_user_or_admin, only: [:edit, :update, :destroy]
  before_action :require_login, only: [:edit, :update, :destroy]

  def home
  end

  def new
    @user = User.new
  end

  def index
    # Admin-only list of users
    @users = User.all
  end

  def create
    @user = User.new(user_params)
    # For public signups ensure the DB column stores the 'user' role (0).
    # Due to enum handling differences, we'll enforce the raw DB value after create
    # for non-admin signups to avoid accidentally creating admin accounts.
    if @user.save
      unless current_user&.admin?
        # write raw integer value directly to the DB to avoid enum mapping quirks
        @user.update_column(:role, User.roles[:user]) rescue nil
        @user.reload
      end

      log_in @user
      redirect_to root_path, notice: "Welcome, #{@user.name}!"
    else
      render :new
    end
  end

  def show
    # @user is set by set_user
  end

  def edit
    # @user is set by set_user
  end

  def update
    # Permit blank password: if password fields are blank, remove them so validations don't force change
    update_params = user_params.dup
    if update_params[:password].blank?
      update_params.delete(:password)
      update_params.delete(:password_confirmation)
    end

    if @user.update(update_params)
      redirect_to @user, notice: "Profile updated successfully."
    else
      # Surface validation feedback so the user understands why the update failed
      flash.now[:alert] = @user.errors.full_messages.to_sentence if @user.errors.any?
      render :edit
    end
  end

  def destroy
    # Only admins or the user themselves can delete (enforced by require_same_user_or_admin)
    @user.destroy
    redirect_to root_path, notice: "User deleted."
  end

  def admin
    # Admin dashboard overview
    @users = User.all
    # Scope reservations to the calendar-visible range for performance
    start_date = params.fetch(:start_date, Date.today).to_date
    range = start_date.beginning_of_month.beginning_of_week..start_date.end_of_month.end_of_week
    @reservations = Reservation.joins(:timeslot).where(timeslots: { date: range }).includes(:user, :table, :timeslot)
    @reservations_by_date = @reservations.group_by { |r| r.timeslot&.date }
    @tables = Table.all
    @timeslots = Timeslot.where(date: range).order(:date, :start_time)
  end

  private

  def user_params
    # Permit :role only when the current_user is an admin. Regular users cannot set their role.
    permitted = [:name, :email, :phone, :password, :password_confirmation]
    permitted << :role if current_user&.admin?

    params.require(:user).permit(permitted)
  end

  def set_user
    @user = User.find(params[:id])
  end

  def require_same_user_or_admin
    return if current_user == @user || current_user&.admin?

    flash[:alert] = "You are not authorized to perform this action."
    redirect_to root_path
  end
end
