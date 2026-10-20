require "rails_helper"

RSpec.describe ApplicationRecord do
  describe "#z3_id" do
    it "namespaces the primary key with the class name" do
      worker = create(:worker)

      expect(worker.z3_id).to eq(:"Worker_#{worker.id}")
    end

    it "is a symbol, because Z3 enum values must be symbols" do
      expect(create(:qualification).z3_id).to be_a(Symbol)
    end

    it "distinguishes records of different classes sharing an id" do
      worker = create(:worker)
      qualification = create(:qualification)
      qualification.update_column(:id, worker.id)

      expect(worker.z3_id).not_to eq(qualification.reload.z3_id)
    end

    it "has a blank id segment before the record is saved" do
      expect(Worker.new.z3_id).to eq(:Worker_)
    end
  end
end
