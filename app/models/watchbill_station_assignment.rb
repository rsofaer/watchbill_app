class WatchbillStationAssignment < ApplicationRecord
  belongs_to :watchbill
  belongs_to :worker
  belongs_to :watchstation
  enum :shift, ["Days", "Swings", "Mids"]
end
