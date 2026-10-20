require "rails_helper"

RSpec.describe WatchsetsGrid do
  it "exposes a name column and a created_at column" do
    expect(described_class.column_names).to eq([ :name, :created_at ])
  end

  context "with no watchsets" do
    it "has no rows" do
      expect(described_class.new.rows).to be_empty
    end

    it "still reports its header" do
      expect(described_class.new.header).to eq([ "Name", "Created at" ])
    end
  end

  context "with a single watchset" do
    it "reads the name and the raw creation time" do
      created = Time.zone.local(2026, 3, 7, 12, 0)
      create(:watchset, name: "Indian Point", created_at: created)

      name, created_at = described_class.new.rows.first

      expect(name).to eq("Indian Point")
      expect(created_at).to eq(created)
    end
  end

  context "with lots of watchsets" do
    it "returns every one of them" do
      create_list(:watchset, 120)

      expect(described_class.new.assets.count).to eq(120)
    end

    it "orders assets by a requested column" do
      create(:watchset, name: "Zulu")
      create(:watchset, name: "Alpha")

      expect(described_class.new(order: :name).assets.map(&:name)).to eq([ "Alpha", "Zulu" ])
    end

    it "reverses the order on request" do
      create(:watchset, name: "Alpha")
      create(:watchset, name: "Zulu")

      grid = described_class.new(order: :name, descending: true)

      expect(grid.assets.map(&:name)).to eq([ "Zulu", "Alpha" ])
    end

    # Datagrid walks #rows in batches, and ActiveRecord's batching replaces any
    # ORDER BY with one on the primary key. So the ordering above reaches
    # #assets -- which is what the views paginate -- but not the rendered table.
    it "ignores that ordering when building rows, because rows are batched by id" do
      create(:watchset, name: "Zulu")
      create(:watchset, name: "Alpha")

      grid = described_class.new(order: :name)

      expect(grid.rows.map(&:first)).to eq([ "Zulu", "Alpha" ])
    end
  end

  describe "the created_at range filter" do
    it "keeps only watchsets created inside the range" do
      old = create(:watchset, name: "Old", created_at: Time.zone.local(2020, 1, 1))
      recent = create(:watchset, name: "Recent", created_at: Time.zone.local(2026, 6, 1))

      grid = described_class.new(created_at: [ Date.new(2026, 1, 1), Date.new(2026, 12, 31) ])

      expect(grid.assets).to contain_exactly(recent)
      expect(grid.assets).not_to include(old)
    end

    it "treats a one-sided range as an open bound" do
      create(:watchset, name: "Old", created_at: Time.zone.local(2020, 1, 1))
      recent = create(:watchset, name: "Recent", created_at: Time.zone.local(2026, 6, 1))

      grid = described_class.new(created_at: [ Date.new(2026, 1, 1), nil ])

      expect(grid.assets).to contain_exactly(recent)
    end

    it "is inert when left blank" do
      create_list(:watchset, 3)

      expect(described_class.new(created_at: [ nil, nil ]).assets.count).to eq(3)
    end
  end

  # The name filter is declared `:integer` against a string column. Datagrid
  # casts the input before comparing, so a non-numeric search term becomes nil
  # and the filter drops out of the query entirely. These examples pin the
  # behaviour that ships today, not the behaviour the form implies.
  describe "the name filter" do
    it "is ignored for an ordinary name, because the filter casts to an integer" do
      create(:watchset, name: "Indian Point")
      create(:watchset, name: "Somewhere Else")

      expect(described_class.new(name: "Indian Point").assets.count).to eq(2)
    end

    it "compares a numeric term against the name column" do
      numeric = create(:watchset, name: "7")
      create(:watchset, name: "Indian Point")

      expect(described_class.new(name: "7").assets).to contain_exactly(numeric)
    end

    it "is inert when left blank" do
      create_list(:watchset, 4)

      expect(described_class.new(name: nil).assets.count).to eq(4)
    end
  end
end
