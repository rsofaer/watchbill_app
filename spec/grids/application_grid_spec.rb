require "rails_helper"

RSpec.describe ApplicationGrid do
  # The two helpers below are shared column builders, so they get exercised
  # through throwaway grids rather than through whichever app grid happens to
  # use them today.
  let(:view_context) { ApplicationController.new.view_context }

  def html_value(grid, column, asset)
    grid.html_value(column, view_context, asset)
  end

  describe ".date_column" do
    let(:grid_class) do
      Class.new(described_class) do
        scope { Watchset }
        date_column(:created_at)
        date_column(:derived) { |watchset| watchset.created_at }
        date_column(:missing) { nil }
        date_column(:headed, header: "Saved on") { |watchset| watchset.created_at }
        date_column(:queried, "'2026-03-07'")
      end
    end

    it "passes a query through to datagrid" do
      watchset = create(:watchset)

      expect(grid_class.new.data_value(:queried, grid_class.new.assets.find(watchset.id))).to eq("2026-03-07")
    end

    it "passes column options through to datagrid" do
      expect(grid_class.new.column_by_name(:headed).header).to eq("Saved on")
    end

    it "keeps the underlying value in the data representation" do
      created = Time.zone.local(2026, 3, 7, 12, 0)
      watchset = create(:watchset, created_at: created)

      expect(grid_class.new.data_value(:created_at, watchset)).to eq(created)
    end

    it "renders mm/dd/yyyy in the html representation" do
      watchset = create(:watchset, created_at: Time.zone.local(2026, 3, 7, 12, 0))

      expect(html_value(grid_class.new, :created_at, watchset)).to eq("03/07/2026")
    end

    it "reads through a block when one is given" do
      watchset = create(:watchset, created_at: Time.zone.local(2026, 12, 25, 9, 0))

      expect(html_value(grid_class.new, :derived, watchset)).to eq("12/25/2026")
    end

    it "renders an em dash when the date is nil" do
      watchset = create(:watchset)

      expect(html_value(grid_class.new, :missing, watchset)).to eq("&mdash;")
    end

    it "marks that em dash html-safe so it is not escaped" do
      watchset = create(:watchset)

      expect(html_value(grid_class.new, :missing, watchset)).to be_html_safe
    end
  end

  describe ".boolean_column" do
    let(:grid_class) do
      Class.new(described_class) do
        scope { Worker }
        boolean_column(:qualified) { |worker| worker.qualifications.any? }
        boolean_column(:name)
        boolean_column(:headed, header: "Valid") { true }
        boolean_column(:queried, "0")
      end
    end

    it "passes a query through to datagrid" do
      worker = create(:worker)

      expect(grid_class.new.data_value(:queried, grid_class.new.assets.find(worker.id))).to eq("Yes")
    end

    it "passes column options through to datagrid" do
      expect(grid_class.new.column_by_name(:headed).header).to eq("Valid")
    end

    it "renders Yes for a truthy value" do
      worker = create(:worker, qualifications: [ create(:qualification) ])

      expect(grid_class.new.data_value(:qualified, worker)).to eq("Yes")
    end

    it "renders No for a falsey value" do
      expect(grid_class.new.data_value(:qualified, create(:worker))).to eq("No")
    end

    it "reads the attribute directly when no block is given" do
      expect(grid_class.new.data_value(:name, create(:worker, name: "Ann"))).to eq("Yes")
    end

    it "treats a nil attribute as No" do
      worker = create(:worker)
      worker.update_column(:name, nil)

      expect(grid_class.new.data_value(:name, worker)).to eq("No")
    end
  end

  it "applies no default column options" do
    expect(described_class.default_column_options).to eq({})
  end
end
