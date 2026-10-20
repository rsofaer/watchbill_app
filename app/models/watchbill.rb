class Watchbill < ApplicationRecord
  belongs_to :watchset
  has_many :watchstations, through: :watchset

  has_many :watchbill_station_assignments
  has_many :workers, through: :watchbill_station_assignments
end

