class CreateTimeslots < ActiveRecord::Migration[8.1]
  def change
    create_table :timeslots do |t|
      t.date :date
      t.time :start_time
      t.time :end_time
      t.integer :max_tables

      t.timestamps
    end
  end
end
