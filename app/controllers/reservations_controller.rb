class ReservationsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :require_login
  before_action :set_reservation, only: [ :show, :edit, :update, :destroy ]

  def index
    # Show only reservations for the currently logged-in user
    @reservations = current_user.reservations.order(created_at: :desc)
  end

  def show; end

  def new
    @reservation = Reservation.new
    prepare_form_dependencies(selected_timeslot_id: params[:timeslot_id])
  end

  def create
    @reservation = current_user.reservations.build(reservation_params)

    if @reservation.save
      redirect_to @reservation, notice: "Reservation created successfully!", status: :see_other
    else
      # Re-populate helper objects when re-rendering the form
      prepare_form_dependencies(selected_timeslot_id: @reservation.timeslot_id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @tables = Table.all
    @timeslots = Timeslot.all
  end

  def update
    if @reservation.update(reservation_params)
      respond_to do |format|
        format.turbo_stream do
          streams = []
          streams << turbo_stream.replace(dom_id(@reservation), partial: 'reservations/admin_row', locals: { reservation: @reservation })
          # Replace the calendar item (if present) so calendar view updates in-place. Calendar item id is "#{dom_id}-calendar".
          streams << turbo_stream.replace("#{dom_id(@reservation)}-calendar", partial: 'reservations/calendar_item', locals: { reservation: @reservation })
          render turbo_stream: streams
        end
        format.html { redirect_to @reservation, notice: "Reservation updated successfully!", status: :see_other }
      end
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

    reservation_dom_id = dom_id(@reservation)
    @reservation.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(reservation_dom_id) }
      format.html { redirect_back fallback_location: reservations_path, notice: "Reservation canceled.", status: :see_other }
    end
  end

  private

  def set_reservation
    if current_user.admin?
      @reservation = Reservation.find(params[:id])
    else
      @reservation = current_user.reservations.find(params[:id])
    end
  end

  def reservation_params
    params.require(:reservation).permit(:table_id, :timeslot_id, :num_people, :status)
  end

  def prepare_form_dependencies(selected_timeslot_id: nil)
    @selected_timeslot = nil

    @timeslots = Timeslot.where("date >= ?", Date.current).order(:date, :start_time)
    @timeslots_by_date = @timeslots.group_by(&:date).transform_values { |slots| slots.sort_by(&:start_time) }

    if selected_timeslot_id.present?
      @selected_timeslot = Timeslot.find_by(id: selected_timeslot_id)

      if @selected_timeslot
        @timeslots_by_date[@selected_timeslot.date] ||= []

        unless @timeslots_by_date[@selected_timeslot.date].any? { |slot| slot.id == @selected_timeslot.id }
          @timeslots_by_date[@selected_timeslot.date] << @selected_timeslot
          @timeslots_by_date[@selected_timeslot.date].sort_by!(&:start_time)
        end

        @timeslots = (@timeslots + [ @selected_timeslot ]).uniq { |slot| slot.id }
        @timeslots.sort_by! { |slot| [ slot.date, slot.start_time ] }
      end
    end

    if @selected_timeslot
      reserved_table_ids = Reservation.where(timeslot_id: @selected_timeslot.id).pluck(:table_id)
      @tables = reserved_table_ids.any? ? Table.where.not(id: reserved_table_ids) : Table.all
    else
      @tables = Table.all
    end
  end
end
