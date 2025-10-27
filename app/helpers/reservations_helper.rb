module ReservationsHelper
  # Returns true if the reservation can still be canceled (more than 2 hours before start)
  def cancellable?(reservation)
    # Only allow cancellation for reservations that exist, have a timeslot, and
    # are in a cancellable state (pending or confirmed). Cancelled or
    # completed reservations are not cancellable.
    return false unless reservation.present?
    return false unless %w[pending confirmed].include?(reservation.status.to_s)
    return false unless reservation.timeslot && reservation.timeslot.date && reservation.timeslot.start_time

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

  # Returns a hex color string for a reservation status.
  # Centralizes the mapping so views and components render consistent colors.
  def reservation_status_color(reservation_or_status)
    status = reservation_or_status.respond_to?(:status) ? reservation_or_status.status.to_s : reservation_or_status.to_s
    case status
    when 'pending' then '#ffc107'   # Bootstrap warning (yellow)
    when 'confirmed' then '#198754' # Bootstrap success (green)
    when 'cancelled' then '#6c757d' # Bootstrap secondary (gray)
    when 'completed' then '#0dcaf0' # Bootstrap info (cyan)
    else '#adb5bd'                  # muted / light gray
    end
  end

  # Choose readable text color (black or white) depending on background hex color luminance.
  def badge_text_color(hex)
    hex = hex.to_s.delete('#')
    return '#000' if hex.length != 6
    r, g, b = hex.scan(/../).map { |c| c.to_i(16) }
    # Perceived luminance formula
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    luminance > 186 ? '#000' : '#fff'
  end

  # Render a status badge (with a colored dot) linking to the reservation show page.
  # Usage: <%= reservation_status_badge(reservation) %>
  def reservation_status_badge(reservation)
    color = reservation_status_color(reservation)
    text_color = badge_text_color(color)
    label = reservation.status.to_s.humanize

    dot = content_tag(:span, '', style: "background: #{color}; width:10px; height:10px; display:inline-block; border-radius:50%; vertical-align:middle; margin-right:6px;")
    badge = content_tag(:span, label, style: "background: #{color}; color: #{text_color}; padding: .25rem .5rem; border-radius:.25rem; font-size:.75rem; display:inline-block; vertical-align:middle;")

    link_to reservation_path(reservation), class: 'text-decoration-none' do
      safe_join([dot, badge])
    end
  end
end
