class ReservationsController < ApplicationController
  before_action :require_login
  before_action :set_reservation, only: [ :show, :edit, :update, :destroy ]

  def index
    # Show only reservations for the currently logged-in user
    @reservations = current_user.reservations.order(created_at: :desc)
  end

  def show; end

  def new
    @reservation = Reservation.new
    @timeslots = Timeslot.order(:date, :start_time)

    # If a timeslot is pre-selected (e.g., user clicked a slot), show only available tables
    if params[:timeslot_id].present?
      @selected_timeslot = Timeslot.find_by(id: params[:timeslot_id])
      reserved_table_ids = Reservation.where(timeslot_id: @selected_timeslot)&.pluck(:table_id) || []
      @tables = Table.where.not(id: reserved_table_ids)
    else
      @tables = Table.all
    end
  end

  def create
    @reservation = current_user.reservations.build(reservation_params)

    if @reservation.save
      redirect_to @reservation, notice: "Reservation created successfully!", status: :see_other
    else
      # Re-populate helper objects when re-rendering the form
      @timeslots = Timeslot.order(:date, :start_time)
      if @reservation.timeslot
        reserved_table_ids = Reservation.where(timeslot_id: @reservation.timeslot)&.pluck(:table_id) || []
        @tables = Table.where.not(id: reserved_table_ids)
      else
        @tables = Table.all
      end
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @tables = Table.all
    @timeslots = Timeslot.all
  end

  def update
    if @reservation.update(reservation_params)
      redirect_to @reservation, notice: "Reservation updated successfully!", status: :see_other
    else
      @tables = Table.all
      @timeslots = Timeslot.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Prevent cancellation within 2 hours of the reservation start
    if @reservation.timeslot && @reservation.timeslot.date && @reservation.timeslot.start_time
      start_of_reservation = Time.zone.local(
        @reservation.timeslot.date.year,
        @reservation.timeslot.date.month,
        @reservation.timeslot.date.day,
        @reservation.timeslot.start_time.hour,
        @reservation.timeslot.start_time.min,
        @reservation.timeslot.start_time.sec
      )

      if start_of_reservation < 2.hours.from_now
        redirect_to reservations_path, alert: "Cannot cancel reservations less than 2 hours before the start time.", status: :see_other
        return
      end
    end

    @reservation.destroy
    redirect_to reservations_path, notice: "Reservation canceled.", status: :see_other
  end

  private

  def set_reservation
    # Ensure users can only access their own reservations
    @reservation = current_user.reservations.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(:table_id, :timeslot_id, :num_people)
  end
end
