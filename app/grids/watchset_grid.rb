class WatchsetGrid < ApplicationGrid

  attr_accessor :watchbill
  scope do
    Watchstation
  end
  column(:name, header: "Watchstation")
  WatchbillStationAssignment.shifts.each_key do |shift|
    column(:"worker_#{shift.downcase}", header: shift, order: false) do |watchstation, grid|
      assigned = grid.watchbill&.watchbill_station_assignments&.find { |wsa| wsa.watchstation_id == watchstation.id && wsa.shift == shift }
      assigned&.worker&.name
    end
  end

end
