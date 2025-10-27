class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :table
  belongs_to :timeslot

  # Use explicit positional first argument to avoid potential keyword-only
  # argument parsing issues on some Ruby versions (see `User` model for
  # reference).
  enum :status, { pending: 0, confirmed: 1, cancelled: 2, completed: 3 }

  validates :num_people, presence: true, numericality: { greater_than: 0 }
  validate :table_capacity_check
  validate :two_hours_before_rule
  validate :table_availability
  validate :single_reservation_per_user_per_timeslot

  private

  def table_capacity_check
    if table && num_people && num_people > table.capacity
      errors.add(:num_people, "exceeds the table's capacity")
    end
  end

  def two_hours_before_rule
    return unless timeslot && timeslot.date && timeslot.start_time

    # Build a timezone-aware DateTime for the timeslot start so we compare
    # the actual start datetime against now + 2 hours. This is robust even
    # when `start_time` is stored as a time-of-day without a date component.
    start_of_reservation = Time.zone.local(
      timeslot.date.year,
      timeslot.date.month,
      timeslot.date.day,
      timeslot.start_time.hour,
      timeslot.start_time.min,
      timeslot.start_time.sec
    )

    if start_of_reservation < 2.hours.from_now
      errors.add(:timeslot, "must be booked at least 2 hours in advance")
    end
  end

  def table_availability
    return unless table && timeslot

    # If another reservation exists for the same table and timeslot, it's unavailable
    conflict = Reservation.where(table_id: table.id, timeslot_id: timeslot.id)
    conflict = conflict.where.not(id: id) if persisted?
    if conflict.exists?
      errors.add(:table, "is already booked for that timeslot")
    end
  end

  # Prevent a user from creating more than one reservation for the same timeslot.
  # This is intentionally strict: even if the table capacity or other slots
  # would allow another booking, a user may not hold multiple bookings for the
  # same timeslot. Cancelled reservations are ignored.
  def single_reservation_per_user_per_timeslot
    return unless user && timeslot

    conflict = Reservation.where(user_id: user.id, timeslot_id: timeslot.id)
    conflict = conflict.where.not(id: id) if persisted?
    # Exclude cancelled reservations from blocking (allow rebooking after cancel)
    conflict = conflict.where.not(status: Reservation.statuses[:cancelled])

    if conflict.exists?
      errors.add(:base, "You already have a reservation for this timeslot")
    end
  end
end
