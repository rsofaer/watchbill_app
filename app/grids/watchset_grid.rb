class WatchsetGrid < ApplicationGrid

  attr_accessor :watchbill
  scope do
    Watchstation
  end
  column(:name, header: "Watchstation")
  column(:worker_qualification_days, header: "Days") do |watchstation, grid|
    assigned = grid.watchbill.watchbill_station_assignments.to_a.filter { |wsa| wsa.watchstation == watchstation && wsa.shift == "Days" }.first
    assigned&.worker&.name
  end
  column(:worker_qualification_swings, header: "Swings") do |watchstation, grid|
    assigned = grid.watchbill.watchbill_station_assignments.to_a.filter { |wsa| wsa.watchstation == watchstation && wsa.shift == "Swings" }.first
    assigned&.worker&.name
  end
  column(:worker_qualification_mids, header: "Mids") do |watchstation, grid|
    assigned = grid.watchbill.watchbill_station_assignments.to_a.filter { |wsa| wsa.watchstation == watchstation && wsa.shift == "Mids" }.first
    assigned&.worker&.name
  end

end
