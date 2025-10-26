class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  # Make session helper methods available to controllers (e.g. log_in, log_out)
  include SessionsHelper

  def home
    @start_date = safe_start_date
    @user_reservations = []
    @reservations_by_date = {}

    return unless logged_in?

    visible_range = @start_date.beginning_of_month.beginning_of_week..@start_date.end_of_month.end_of_week
  @user_reservations = current_user.reservations
                   .joins(:timeslot)
                   .where(timeslots: { date: visible_range })
                   .includes(:timeslot, :table)
                   .order('timeslots.date ASC, timeslots.start_time ASC')
    @reservations_by_date = @user_reservations.group_by { |reservation| reservation.timeslot&.date }
  end

  private

  def safe_start_date
    candidate = params[:start_date]
    return Date.current if candidate.blank?

    Date.parse(candidate.to_s)
  rescue ArgumentError
    Date.current
  end

end
