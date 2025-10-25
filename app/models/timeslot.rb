class Timeslot < ApplicationRecord
  has_many :reservations, dependent: :destroy

  validates :date, :start_time, :end_time, presence: true
  validate :end_after_start

  private

  def end_after_start
    return if end_time.blank? || start_time.blank?

    opening_seconds = 7.hours.to_i
    closing_seconds = 22.hours.to_i

    start_seconds = start_time.seconds_since_midnight.to_i
    end_seconds = end_time.seconds_since_midnight.to_i

    if start_seconds < opening_seconds || start_seconds > closing_seconds
      errors.add(:start_time, "must be between 07:00 and 22:00")
    end

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
end
