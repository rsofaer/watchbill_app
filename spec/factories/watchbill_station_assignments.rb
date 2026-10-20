FactoryBot.define do
  factory :watchbill_station_assignment do
    watchbill
    watchstation
    worker
    shift { "Days" }
  end
end
