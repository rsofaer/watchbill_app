require "rails_helper"

RSpec.describe Qualification do
  it "has no workers when nothing is qualified" do
    expect(create(:qualification).workers).to be_empty
  end

  it "reaches its workers through worker_qualifications" do
    qualification = create(:qualification)
    worker = create(:worker, qualifications: [ qualification ])

    expect(qualification.reload.workers).to contain_exactly(worker)
    expect(qualification.worker_qualifications.map(&:worker)).to contain_exactly(worker)
  end

  it "holds many workers" do
    qualification = create(:qualification)
    workers = create_list(:worker, 25, qualifications: [ qualification ])

    expect(qualification.reload.workers).to match_array(workers)
  end
end
