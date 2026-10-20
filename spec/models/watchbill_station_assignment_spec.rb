require "rails_helper"

RSpec.describe WatchbillStationAssignment do
  it "requires a watchbill, a worker and a watchstation" do
    assignment = described_class.new

    expect(assignment).not_to be_valid
    expect(assignment.errors[:watchbill]).to be_present
    expect(assignment.errors[:worker]).to be_present
    expect(assignment.errors[:watchstation]).to be_present
  end

  describe "the shift enum" do
    it "names the three shifts in watchbill order" do
      expect(described_class.shifts.keys).to eq([ "Days", "Swings", "Mids" ])
    end

    it "stores shifts as their array index" do
      expect(described_class.shifts).to eq("Days" => 0, "Swings" => 1, "Mids" => 2)
    end

    it "defaults to the first shift" do
      expect(described_class.new.shift).to eq("Days")
    end

    it "round-trips each shift through the database" do
      described_class.shifts.each_key do |shift|
        assignment = create(:watchbill_station_assignment, shift: shift)

        expect(assignment.reload.shift).to eq(shift)
      end
    end

    it "rejects a shift that is not one of the three" do
      expect { create(:watchbill_station_assignment, shift: "Graveyard") }
        .to raise_error(ArgumentError, /Graveyard/)
    end
  end
end
