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
    @tables = Table.all
    @timeslots = Timeslot.all
  end

  def create
    @reservation = current_user.reservations.build(reservation_params)

    if @reservation.save
      redirect_to @reservation, notice: "Reservation created successfully!"
    else
      @tables = Table.all
      @timeslots = Timeslot.all
      render :new
    end
  end

  def edit
    @tables = Table.all
    @timeslots = Timeslot.all
  end

  def update
    if @reservation.update(reservation_params)
      redirect_to @reservation, notice: "Reservation updated successfully!"
    else
      @tables = Table.all
      @timeslots = Timeslot.all
      render :edit
    end
  end

  def destroy
    @reservation.destroy
    redirect_to reservations_path, notice: "Reservation canceled."
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
