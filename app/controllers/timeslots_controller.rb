class TimeslotsController < ApplicationController
  before_action :require_login
  before_action :set_timeslot, only: [ :edit, :update, :destroy ]

  def index
    @timeslots = Timeslot.order(:date, :start_time)
  end

  def new
    @timeslot = Timeslot.new
  end

  def create
    @timeslot = Timeslot.new(timeslot_params)
    if @timeslot.save
      redirect_to timeslots_path, notice: "Timeslot created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @timeslot.update(timeslot_params)
      redirect_to timeslots_path, notice: "Timeslot updated."
    else
      render :edit
    end
  end

  def destroy
    @timeslot.destroy
    redirect_to timeslots_path, notice: "Timeslot deleted."
  end

  private

  def set_timeslot
    @timeslot = Timeslot.find(params[:id])
  end

  def timeslot_params
    params.require(:timeslot).permit(:date, :start_time, :end_time)
  end
end
