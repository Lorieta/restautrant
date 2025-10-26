class Timeslot < ApplicationRecord
  # Allow a nullable table association for now so existing records don't fail validation.
  belongs_to :table, optional: true
  has_many :reservations, dependent: :destroy

  validates :date, :start_time, presence: true
  validate :end_after_start
  validate :no_overlapping_timeslots

  # When a timeslot has finished (end time is in the past), mark its
  # reservations as completed. This runs after the timeslot is saved so
  # changes to date/start_time/end_time that make the slot 'done' will
  # trigger the transition.
  after_save_commit :complete_reservations_if_done

  private

  def end_after_start
    return if start_time.blank?

    opening_seconds = 7.hours.to_i
    closing_seconds = 22.hours.to_i

    start_seconds = start_time.seconds_since_midnight.to_i

    if start_seconds < opening_seconds || start_seconds > closing_seconds
      errors.add(:start_time, "must be between 07:00 and 22:00")
    end

    # If end_time is blank, skip end-related checks (allow nil end time)
    return if end_time.blank?

    end_seconds = end_time.seconds_since_midnight.to_i

    if end_seconds < opening_seconds || end_seconds > closing_seconds
      errors.add(:end_time, "must be between 07:00 and 22:00")
    end

    return if errors.any?

    if end_seconds <= start_seconds
      errors.add(:end_time, "must be after the start time")
      return
    end

    duration = end_seconds - start_seconds

    if duration < 1.hour
      errors.add(:end_time, "must be at least 1 hour after the start time")
    end
  end

  # Prevent creating timeslots for the same table and date that overlap in time.
  # If `end_time` is nil we use a 1-hour fallback to match the validation behavior above.
  def no_overlapping_timeslots
    return if table_id.blank? || date.blank? || start_time.blank?

    eff_start = start_time
    eff_end = end_time.presence || (start_time + 1.hour)

    candidates = Timeslot.where(table_id: table_id, date: date)
    candidates = candidates.where.not(id: id) if persisted?

    overlapping = candidates.any? do |ts|
      ts_start = ts.start_time
      ts_end = ts.end_time.presence || (ts.start_time + 1.hour)

      # ranges overlap when start_a < end_b && end_a > start_b
      ts_start < eff_end && ts_end > eff_start
    end

    if overlapping
      errors.add(:base, "overlaps an existing timeslot for this table")
    end
  end

  # Return true when this timeslot's end datetime is in the past. If
  # `end_time` is nil we fall back to assuming a 1-hour duration from
  # `start_time` (this mirrors the validation's minimum duration).
  def done?
    return false if date.blank? || start_time.blank?

    effective_end = end_time.presence || (start_time + 1.hour rescue nil)
    return false if effective_end.blank?

    end_dt = Time.zone.local(
      date.year,
      date.month,
      date.day,
      effective_end.hour,
      effective_end.min,
      effective_end.sec
    )

    end_dt < Time.zone.now
  end

  private

  # Mark non-cancelled, non-completed reservations for this timeslot as completed.
  # Uses a single SQL update for efficiency but skips reservations already
  # cancelled or completed.
  def complete_reservations_if_done
    return unless done?

    # Use the enum mapping to get the integer value for :completed and :cancelled
    completed_val = Reservation.statuses[:completed]
    cancelled_val = Reservation.statuses[:cancelled]

    to_complete = reservations.where.not(status: completed_val).where.not(status: cancelled_val)
    return if to_complete.empty?

    to_complete.update_all(status: completed_val, updated_at: Time.zone.now)
  end
end
