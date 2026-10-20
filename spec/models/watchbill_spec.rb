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

RSpec.describe Watchbill, "saving" do
  it "builds its assignments from nested attributes" do
    station = create(:watchstation)
    worker = create(:worker)
    bill = described_class.create!(
      watchset: station.watchset,
      watchbill_station_assignments_attributes: [
        { watchstation_id: station.id, shift: "Mids", worker_id: worker.id }
      ]
    )

    expect(bill.reload.watchbill_station_assignments.map { |a| [ a.watchstation, a.shift, a.worker ] })
      .to eq([ [ station, "Mids", worker ] ])
  end

  it "takes its assignments with it when destroyed" do
    bill = create(:watchbill)
    create(:watchbill_station_assignment, watchbill: bill)

    expect { bill.destroy }.to change(WatchbillStationAssignment, :count).by(-1)
  end
end

RSpec.describe Watchbill, "#staffing_problems" do
  let(:watchset) { create(:watchset, name: "Indian Point") }
  let(:bill) { create(:watchbill, watchset: watchset) }

  def station(name)
    create(:watchstation, name: name, watchset: watchset)
  end

  def qualified_worker(name, *stations)
    create(:worker, name: name, qualifications: stations.map(&:qualification))
  end

  def assign(station, shift, worker)
    create(:watchbill_station_assignment, watchbill: bill, watchstation: station, shift: shift, worker: worker)
  end

  def staff_fully(station)
    WatchbillStationAssignment.shifts.each_key do |shift|
      assign(station, shift, qualified_worker("#{station.name} #{shift}", station))
    end
  end

  it "finds nothing wrong with a watchset that has no watchstations" do
    expect(bill.staffing_problems).to eq([])
    expect(bill).to be_properly_staffed
  end

  it "finds nothing wrong when every station and shift has its own qualified worker" do
    staff_fully(station("Rover"))
    staff_fully(station("Condenser"))

    expect(bill.reload.staffing_problems).to eq([])
    expect(bill).to be_properly_staffed
  end

  it "reports every station and shift nobody is standing" do
    rover = station("Rover")
    assign(rover, "Swings", qualified_worker("Bo", rover))

    expect(bill.reload.staffing_problems)
      .to eq([ "Rover has nobody on Days", "Rover has nobody on Mids" ])
    expect(bill).not_to be_properly_staffed
  end

  it "reports a worker who does not hold the station's qualification" do
    rover = station("Rover")
    staff_fully(rover)
    bill.watchbill_station_assignments.find_by!(shift: "Swings").update!(worker: create(:worker, name: "Ann"))

    expect(bill.reload.staffing_problems).to eq([ "Ann is not qualified for Rover (Swings)" ])
  end

  it "notices a qualification lost after the watchbill was saved" do
    rover = station("Rover")
    staff_fully(rover)
    expect(bill.reload).to be_properly_staffed

    WorkerQualification.find_by!(worker: Worker.find_by!(name: "Rover Mids")).destroy

    expect(bill.reload.staffing_problems).to eq([ "Rover Mids is not qualified for Rover (Mids)" ])
  end

  it "notices a watchstation added after the watchbill was saved" do
    staff_fully(station("Rover"))
    expect(bill.reload).to be_properly_staffed

    station("Condenser")

    expect(bill.reload.staffing_problems).to eq([
      "Condenser has nobody on Days", "Condenser has nobody on Swings", "Condenser has nobody on Mids"
    ])
  end

  it "reports a station and shift with more than one worker on it" do
    rover = station("Rover")
    staff_fully(rover)
    assign(rover, "Mids", qualified_worker("Extra", rover))

    expect(bill.reload.staffing_problems).to eq([ "Rover has more than one worker on Mids" ])
  end

  it "reports a worker standing more than one watch" do
    rover = station("Rover")
    condenser = station("Condenser")
    staff_fully(rover)
    staff_fully(condenser)
    both = qualified_worker("Both", rover, condenser)
    bill.watchbill_station_assignments.find_by!(watchstation: rover, shift: "Mids").update!(worker: both)
    bill.watchbill_station_assignments.find_by!(watchstation: condenser, shift: "Mids").update!(worker: both)

    expect(bill.reload.staffing_problems).to eq([ "Both is assigned to more than one watch" ])
  end

  it "reports an assignment to a watchstation from another watchset" do
    staff_fully(station("Rover"))
    elsewhere = create(:watchstation, name: "Drydock Rover")
    assign(elsewhere, "Days", qualified_worker("Visitor", elsewhere))

    expect(bill.reload.staffing_problems).to eq([ "Drydock Rover is not a watchstation in Indian Point" ])
  end

  it "checks assignments that have been built but not saved" do
    rover = station("Rover")
    unsaved = described_class.new(watchset: watchset)
    WatchbillStationAssignment.shifts.each_key do |shift|
      unsaved.watchbill_station_assignments.build(watchstation: rover, shift: shift,
                                                  worker: qualified_worker(shift, rover))
    end

    expect(unsaved).to be_properly_staffed
  end
end
