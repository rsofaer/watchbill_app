require "rails_helper"

RSpec.describe WorkersGrid do
  it "exposes a name column and a qualifications column" do
    expect(described_class.column_names).to eq([ :name, :qualifications ])
  end

  it "does not offer ordering by qualifications" do
    expect(described_class.new.column_by_name(:qualifications)).not_to be_supports_order
  end

  context "with no workers" do
    it "has no rows" do
      expect(described_class.new.rows).to be_empty
    end
  end

  context "with a worker" do
    it "reads the name and lists qualifications alphabetically" do
      create(:worker, name: "Alice", qualifications: [
        create(:qualification, name: "Reactor Operator"),
        create(:qualification, name: "Fire Watch")
      ])

      expect(described_class.new.rows).to eq([ [ "Alice", "Fire Watch, Reactor Operator" ] ])
    end

    it "leaves the qualifications cell blank for an unqualified worker" do
      create(:worker, name: "Bob")

      expect(described_class.new.rows).to eq([ [ "Bob", "" ] ])
    end
  end

  it "preloads qualifications" do
    create(:worker, qualifications: [ create(:qualification) ])

    expect(described_class.new.assets.first.association(:qualifications)).to be_loaded
  end
end
