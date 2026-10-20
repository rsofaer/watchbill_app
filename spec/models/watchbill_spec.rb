require "rails_helper"

RSpec.describe Watchbill do
  it "requires a watchset" do
    bill = described_class.new

    expect(bill).not_to be_valid
    expect(bill.errors[:watchset]).to be_present
  end

  it "reaches watchstations through its watchset" do
    watchset = create(:watchset)
    stations = create_list(:watchstation, 3, watchset: watchset)
    bill = create(:watchbill, watchset: watchset)

    expect(bill.watchstations).to match_array(stations)
  end

  it "has no watchstations when the watchset has none" do
    expect(create(:watchbill).watchstations).to be_empty
  end

  it "has no assignments until some are added" do
    expect(create(:watchbill).watchbill_station_assignments).to be_empty
  end

  it "reaches its workers through its assignments" do
    bill = create(:watchbill)
    worker = create(:worker)
    create(:watchbill_station_assignment, watchbill: bill, worker: worker)

    expect(bill.reload.workers).to contain_exactly(worker)
  end
end
