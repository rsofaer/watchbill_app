require "rails_helper"

RSpec.describe WatchbillsGrid do
  # link_to needs a request to build a url against.
  let(:view_context) do
    ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create }.view_context
  end

  it "lists a link, the save date and whether the watchbill is valid" do
    expect(described_class.column_names).to eq([ :id, :created_at, :properly_staffed? ])
    expect(described_class.new.html_columns.map(&:header)).to eq([ "Watchbill", "Saved on", "Valid" ])
  end

  it "lists the most recently saved watchbill first" do
    older = create(:watchbill, created_at: 2.days.ago)
    newer = create(:watchbill, created_at: 1.day.ago)

    expect(described_class.new.assets.to_a).to eq([ newer, older ])
  end

  it "links each row to its watchbill" do
    bill = create(:watchbill)

    expect(described_class.new.html_value(:id, view_context, bill))
      .to eq(%(<a href="/watchbills/#{bill.id}">Watchbill ##{bill.id}</a>))
  end

  it "formats the save date as mm/dd/yyyy" do
    bill = create(:watchbill, created_at: Time.zone.local(2026, 3, 7, 12, 0))

    expect(described_class.new.html_value(:created_at, view_context, bill)).to eq("03/07/2026")
  end

  it "says Yes for a properly staffed watchbill" do
    expect(described_class.new.data_value(:properly_staffed?, create(:watchbill))).to eq("Yes")
  end

  it "says No for a watchbill with staffing problems" do
    bill = create(:watchstation).then { |station| create(:watchbill, watchset: station.watchset) }

    expect(described_class.new.data_value(:properly_staffed?, bill)).to eq("No")
  end

  it "does not offer to sort by validity, which is not a database column" do
    expect(described_class.new.column_by_name(:properly_staffed?)).not_to be_supports_order
  end
end
