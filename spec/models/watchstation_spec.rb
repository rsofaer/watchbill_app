require "rails_helper"

RSpec.describe Watchstation do
  it "requires a watchset" do
    station = described_class.new(name: "Rover", qualification: create(:qualification))

    expect(station).not_to be_valid
    expect(station.errors[:watchset]).to be_present
  end

  it "requires a qualification" do
    station = described_class.new(name: "Rover", watchset: create(:watchset))

    expect(station).not_to be_valid
    expect(station.errors[:qualification]).to be_present
  end

  it "belongs to a watchset and a qualification" do
    station = create(:watchstation)

    expect(station.watchset).to be_a(Watchset)
    expect(station.qualification).to be_a(Qualification)
  end
end
