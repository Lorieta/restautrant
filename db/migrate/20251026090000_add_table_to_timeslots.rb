class AddTableToTimeslots < ActiveRecord::Migration[8.1]
  def change
    # Add the reference as nullable first so existing timeslots don't break migration.
    unless column_exists?(:timeslots, :table_id)
      add_reference :timeslots, :table, foreign_key: true, null: true
    end
  end
end
