class Table < ApplicationRecord
  # Replace 'name' with 'quantity' and 'seats' with 'capacity'.
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :capacity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  has_many :timeslots, dependent: :destroy
  has_many :reservations
  accepts_nested_attributes_for :timeslots
end
