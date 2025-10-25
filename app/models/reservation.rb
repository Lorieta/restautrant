class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :table
  belongs_to :timeslot

  validates :num_people, presence: true, numericality: { greater_than: 0 }
  validate :table_capacity_check
  validate :two_hours_before_rule

  private

  def table_capacity_check
    if table && num_people && num_people > table.seats
      errors.add(:num_people, "exceeds the table's seat capacity")
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
end
