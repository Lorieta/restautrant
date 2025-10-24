class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :table
  belongs_to :timeslot
end
