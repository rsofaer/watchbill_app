class Watchstation < ApplicationRecord
  belongs_to :watchset
  belongs_to :qualification
  has_many :watchbill_station_assignments, dependent: :destroy

  validates :name, presence: true
end
