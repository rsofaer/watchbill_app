require "rails_helper"

RSpec.describe WorkerQualification do
  it "requires a worker" do
    record = described_class.new(qualification: create(:qualification))

    expect(record).not_to be_valid
    expect(record.errors[:worker]).to be_present
  end

  it "requires a qualification" do
    record = described_class.new(worker: create(:worker))

    expect(record).not_to be_valid
    expect(record.errors[:qualification]).to be_present
  end

  it "joins a worker to a qualification" do
    record = create(:worker_qualification)

    expect(record.worker).to be_a(Worker)
    expect(record.qualification).to be_a(Qualification)
  end
end
