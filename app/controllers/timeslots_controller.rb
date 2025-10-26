class TimeslotsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :require_login
  before_action :set_timeslot, only: [ :edit, :update, :destroy ]

  def index
    # Determine the calendar start date from params (fallback to today)
    start_date = params.fetch(:start_date, Date.today).to_date

    # Scope the query to the month view range so the calendar only loads visible events
    range = start_date.beginning_of_month.beginning_of_week..start_date.end_of_month.end_of_week

    @timeslots = Timeslot.where(date: range).order(:date, :start_time)
    # Pre-group timeslots by date for reliable rendering in the calendar view
    @timeslots_by_date = @timeslots.group_by(&:date)
    # Ensure the tables list is available for the top section of the view
  # Some deployments don't have a `name` column on tables; order by id instead
  @tables = Table.all.order(:id)
  end

  def new
    # allow pre-filling table_id when coming from a table context
    @timeslot = Timeslot.new(table_id: params[:table_id])
  end

  def create
    @timeslot = Timeslot.new(timeslot_params)
    if @timeslot.save
      redirect_to admin_dashboard_path, notice: "Timeslot created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @timeslot.update(timeslot_params)
      redirect_to timeslots_path, notice: "Timeslot updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    timeslot_dom_id = dom_id(@timeslot)
    @timeslot.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(timeslot_dom_id) }
      format.html { redirect_back fallback_location: timeslots_path, notice: "Timeslot deleted." }
    end
  end

  private

  def set_timeslot
    @timeslot = Timeslot.find(params[:id])
  end

  def timeslot_params
    params.require(:timeslot).permit(:date, :start_time, :end_time, :table_id)
  end
end
