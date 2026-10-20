require "rails_helper"

RSpec.describe Watchset do
  describe "validations" do
    it "requires a name" do
      watchset = build(:watchset, name: " ")

      expect(watchset).not_to be_valid
      expect(watchset.errors[:name]).to be_present
    end

    it "is valid with a name" do
      expect(build(:watchset, name: "Drydock")).to be_valid
    end
  end

  describe "associations" do
    it "has no watchstations, qualifications or workers when empty" do
      watchset = create(:watchset)

      expect(watchset.watchstations).to be_empty
      expect(watchset.qualifications).to be_empty
      expect(watchset.workers).to be_empty
    end

    it "reaches qualifications through its watchstations" do
      watchset = create(:watchset)
      qualification = create(:qualification)
      create(:watchstation, watchset: watchset, qualification: qualification)

      expect(watchset.qualifications).to contain_exactly(qualification)
    end

    it "reaches workers through the qualifications its stations require" do
      watchset = create(:watchset)
      qualification = create(:qualification)
      create(:watchstation, watchset: watchset, qualification: qualification)
      worker = create(:worker, qualifications: [ qualification ])

      expect(watchset.workers).to contain_exactly(worker)
    end

    it "excludes workers who hold none of the required qualifications" do
      watchset = create(:watchset)
      create(:watchstation, watchset: watchset, qualification: create(:qualification))
      create(:worker, qualifications: [ create(:qualification) ])

      expect(watchset.workers).to be_empty
    end

    it "lists a worker once per qualification they hold, so callers must distinct it" do
      watchset = create(:watchset)
      qualifications = create_list(:qualification, 3)
      qualifications.each { |q| create(:watchstation, watchset: watchset, qualification: q) }
      worker = create(:worker, qualifications: qualifications)

      expect(watchset.workers.to_a).to eq([ worker, worker, worker ])
      expect(watchset.workers.distinct.to_a).to eq([ worker ])
    end

    it "carries many watchstations" do
      watchset = create(:watchset)
      stations = create_list(:watchstation, 30, watchset: watchset)

      expect(watchset.watchstations).to match_array(stations)
    end
  end

  # #generate_watchbill bails out before it builds any Z3 sort whenever one of
  # the three sets it needs is empty. Solver runs are covered in
  # spec/models/watchset_solver_spec.rb.
  describe "#generate_watchbill when there is nothing to solve" do
    it "returns nil for a watchset with no watchstations at all" do
      expect(create(:watchset).generate_watchbill).to be_nil
    end

    it "returns nil when there are watchstations but nobody is qualified" do
      watchset = create(:watchset)
      create_list(:watchstation, 3, watchset: watchset)

      expect(watchset.workers).to be_empty
      expect(watchset.generate_watchbill).to be_nil
    end

    it "returns nil when qualified workers exist but belong to another watchset" do
      watchset = create(:watchset)
      other_qualification = create(:qualification)
      create(:watchstation, watchset: create(:watchset), qualification: other_qualification)
      create(:worker, qualifications: [ other_qualification ])

      expect(watchset.generate_watchbill).to be_nil
    end

    it "does not persist anything" do
      watchset = create(:watchset)
      create_list(:watchstation, 2, watchset: watchset)

      expect { watchset.generate_watchbill }.not_to change(Watchbill, :count)
    end
  end
end
