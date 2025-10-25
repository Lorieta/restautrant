class Table < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :seats, presence: true, numericality: { greater_than: 0 }
end
