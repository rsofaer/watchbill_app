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

  it "will not give a worker the same qualification twice" do
    existing = create(:worker_qualification)
    duplicate = described_class.new(worker: existing.worker, qualification: existing.qualification)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:qualification]).to be_present
  end

  it "lets different workers hold the same qualification" do
    existing = create(:worker_qualification)

    expect(described_class.new(worker: create(:worker), qualification: existing.qualification)).to be_valid
  end
end
