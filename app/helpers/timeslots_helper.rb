module TimeslotsHelper
  # Number of tables free for a given timeslot
  def available_tables_count(timeslot)
    return 0 unless timeslot
    total_tables = Table.count
    reserved = Reservation.where(timeslot_id: timeslot.id).count
    [ total_tables - reserved, 0 ].max
  end

  # Returns ActiveRecord::Relation of tables that are not reserved for the provided timeslot
  def available_tables_for(timeslot)
    return Table.none unless timeslot
    reserved_ids = Reservation.where(timeslot_id: timeslot.id).pluck(:table_id)
    Table.where.not(id: reserved_ids)
  end
end
