class AddUniqueIndexToReservations < ActiveRecord::Migration[8.1]
  def change
    # Prevent double-booking the same table for the same timeslot at the database level
    add_index :reservations, [:table_id, :timeslot_id], unique: true, name: 'index_reservations_on_table_and_timeslot'
  end
end
