require "rails_helper"

RSpec.describe Worker do
  it "has no qualifications by default" do
    expect(create(:worker).qualifications).to be_empty
  end

  it "reaches its qualifications through worker_qualifications" do
    qualification = create(:qualification)
    worker = create(:worker, qualifications: [ qualification ])

    expect(worker.reload.qualifications).to contain_exactly(qualification)
    expect(worker.worker_qualifications.map(&:qualification)).to contain_exactly(qualification)
  end

  it "holds many qualifications" do
    qualifications = create_list(:qualification, 8)
    worker = create(:worker, qualifications: qualifications)

    expect(worker.reload.qualifications).to match_array(qualifications)
  end
end
