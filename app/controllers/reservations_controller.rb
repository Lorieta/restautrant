class ReservationsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :require_login
  before_action :set_reservation, only: [ :show, :edit, :update, :destroy, :cancel ]

  def index
    # Show only reservations for the currently logged-in user
    @reservations = current_user.reservations.order(created_at: :desc)
  end

  def show; end

  def new
    @reservation = Reservation.new
    prepare_form_dependencies(selected_timeslot_id: params[:timeslot_id])
  end

  # POST/GET /reservations/confirm
  # For POST: redirect (303) to the GET confirm with reservation params in the query string.
  # This ensures Turbo receives a redirect response for a non-GET form submission.
  # For GET: build a non-persisted reservation from params and render the confirmation page.
  def confirm
    if request.post?
      # Redirect to GET with params so Turbo sees a redirect (see_other)
      redirect_to confirm_reservations_path(reservation: reservation_params.to_h), status: :see_other
      return
    end

    # GET /reservations/confirm — build the preview reservation
    if params[:reservation].present?
      @reservation = current_user.reservations.build(reservation_params)
      prepare_form_dependencies(selected_timeslot_id: @reservation.timeslot_id)

      if @reservation.invalid?
        # Show the form with validation errors
        render :new, status: :unprocessable_entity
      else
        render :confirm
      end
    else
      redirect_to new_reservation_path, alert: "No reservation data provided for confirmation."
    end
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
      # Ensure the reservation and its associations reflect the persisted state
      # before rendering partials (reload clears any cached association targets).
      @reservation.reload

      respond_to do |format|
        format.turbo_stream do
          streams = []
          streams << turbo_stream.replace(dom_id(@reservation), partial: "reservations/admin_row", locals: { reservation: @reservation })
          # Replace the calendar item (if present) so calendar view updates in-place. Calendar item id is "#{dom_id}-calendar".
          streams << turbo_stream.replace("#{dom_id(@reservation)}-calendar", partial: "reservations/calendar_item", locals: { reservation: @reservation })
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

  def cancel
    # If this was a GET request (user navigated to the URL directly), do not perform
    # the cancellation — redirect safely with a helpful message. Only allow side
    # effects for PATCH requests (method from the Cancel button).
    if request.get?
      redirect_to reservation_path(@reservation), alert: "Use the Cancel button to cancel this reservation."
      return
    end

    # Prevent cancellation within 2 hours of the reservation start or if it already started
    if @reservation.timeslot && @reservation.timeslot.date && @reservation.timeslot.start_time
      start_of_reservation = Time.zone.local(
        @reservation.timeslot.date.year,
        @reservation.timeslot.date.month,
        @reservation.timeslot.date.day,
        @reservation.timeslot.start_time.hour,
        @reservation.timeslot.start_time.min,
        @reservation.timeslot.start_time.sec
      )

      if start_of_reservation < 2.hours.from_now || start_of_reservation <= Time.zone.now
        redirect_to reservations_path, alert: "Cannot cancel reservations less than 2 hours before the start time or after it has started.", status: :see_other
        return
      end
    end

    @reservation.status = :cancelled

    if @reservation.save
      @reservation.reload

      respond_to do |format|
        format.turbo_stream do
          streams = []
          streams << turbo_stream.replace(dom_id(@reservation), partial: "reservations/card", locals: { reservation: @reservation, user: @reservation.user })
          streams << turbo_stream.replace("#{dom_id(@reservation)}-calendar", partial: "reservations/calendar_item", locals: { reservation: @reservation })
          render turbo_stream: streams
        end
        format.html { redirect_back fallback_location: reservations_path, notice: "Reservation canceled.", status: :see_other }
      end
    else
      redirect_back fallback_location: reservations_path, alert: @reservation.errors.full_messages.to_sentence
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

  public

  # GET /reservations/timeslots_for_table?table_id=123
  # Returns JSON list of upcoming timeslots that are appropriate for the
  # provided table and not already reserved for that table.
  def timeslots_for_table
    table = Table.find_by(id: params[:table_id])

    timeslots = if table
      Timeslot.where("date >= ?", Date.current)
              .where("table_id IS NULL OR table_id = ?", table.id)
              .where.not(id: Reservation.where(table_id: table.id).select(:timeslot_id))
              .order(:date, :start_time)
    else
      Timeslot.none
    end

    render json: timeslots.map { |ts|
      label = "#{ts.date} - #{ts.start_time.strftime('%I:%M %p')}"
      label += ts.end_time ? " – #{ts.end_time.strftime('%I:%M %p')}" : " – Open-ended"
      { id: ts.id, date: ts.date, label: label }
    }
  end
end
