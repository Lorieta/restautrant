module ReservationsHelper
	# Returns true if the reservation can still be canceled (more than 2 hours before start)
	def cancellable?(reservation)
		return false unless reservation&.timeslot && reservation.timeslot.date && reservation.timeslot.start_time

		start_of_reservation = Time.zone.local(
			reservation.timeslot.date.year,
			reservation.timeslot.date.month,
			reservation.timeslot.date.day,
			reservation.timeslot.start_time.hour,
			reservation.timeslot.start_time.min,
			reservation.timeslot.start_time.sec
		)

		start_of_reservation >= 2.hours.from_now
	end
end
