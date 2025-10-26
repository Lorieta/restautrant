class AddQuantityAndRenameSeats < ActiveRecord::Migration[8.1]
  def up
    # Add quantity column nullable at first to avoid blocking
    add_column :tables, :quantity, :integer, default: 1, null: true

    # Rename seats -> capacity (seats already integer so safe)
    if column_exists?(:tables, :seats)
      rename_column :tables, :seats, :capacity
    end

    # Backfill quantity from name where possible (extract digits), fallback to 1
    say_with_time "Backfilling table.quantity from name" do
      klass = Class.new(ActiveRecord::Base) do
        self.table_name = 'tables'
      end

      klass.reset_column_information
      klass.find_each do |t|
        q = 1
        if t.respond_to?(:name) && t.name.present?
          m = t.name.match(/(\d+)/)
          q = m[1].to_i if m
        end
        t.update_column(:quantity, q)
      end
    end

    # Now make quantity NOT NULL
    change_column_null :tables, :quantity, false

    # Finally remove name column if it exists
    if column_exists?(:tables, :name)
      remove_column :tables, :name
    end
  end

  def down
    # Recreate name column (best-effort)
    add_column :tables, :name, :string unless column_exists?(:tables, :name)

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'tables'
    end
    klass.reset_column_information
    klass.find_each.with_index(1) do |t, idx|
      t.update_column(:name, "Table #{t.quantity || idx}")
    end

    # Rename capacity back to seats if necessary
    if column_exists?(:tables, :capacity) && !column_exists?(:tables, :seats)
      rename_column :tables, :capacity, :seats
    end

    # Remove quantity
    remove_column :tables, :quantity if column_exists?(:tables, :quantity)
  end
end
