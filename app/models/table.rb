class Table < ApplicationRecord
  # Replace 'name' with 'quantity' and 'seats' with 'capacity'.
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :capacity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  has_many :timeslots, dependent: :destroy
  # Prevent deleting a table while reservations still reference it. This avoids
  # raising a database-level foreign key violation. Attempts to destroy a
  # table with existing reservations will add an error on the table object and
  # cause `destroy` to return false.
  has_many :reservations, dependent: :restrict_with_error
  accepts_nested_attributes_for :timeslots
end
