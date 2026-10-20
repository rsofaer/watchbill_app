require "rails_helper"

RSpec.describe WatchsetGrid do
  let(:watchset) { create(:watchset) }
  let(:watchbill) { create(:watchbill, watchset: watchset) }

  def grid_for(watchbill, watchset: nil)
    described_class.new(watchbill: watchbill) do |scope|
      watchset ? scope.where(watchset: watchset) : scope
    end
  end

  it "lists a station column and one column per shift" do
    expect(described_class.column_names)
      .to eq([ :name, :worker_qualification_days, :worker_qualification_swings, :worker_qualification_mids ])
  end

  it "heads the columns with the station and the three shift names" do
    expect(described_class.new(watchbill: watchbill).header)
      .to eq([ "Watchstation", "Days", "Swings", "Mids" ])
  end

  context "when the watchset has no watchstations" do
    it "has no rows" do
      expect(grid_for(watchbill, watchset: watchset).rows).to be_empty
    end

    # This is why the show page survives an empty watchset even though
    # #generate_watchbill handed it nil: with no rows, no column block runs.
    it "has no rows even when the watchbill is nil" do
      expect(grid_for(nil, watchset: watchset).rows).to be_empty
    end
  end

  context "when stations are unassigned" do
    it "leaves every shift blank" do
      create(:watchstation, name: "Rover", watchset: watchset)

      expect(grid_for(watchbill, watchset: watchset).rows)
        .to eq([ [ "Rover", nil, nil, nil ] ])
    end
  end

  context "when a station is fully assigned" do
    it "names the worker on watch in each shift column" do
      station = create(:watchstation, name: "Rover", watchset: watchset)
      {
        "Days" => "Ann", "Swings" => "Bo", "Mids" => "Cy"
      }.each do |shift, name|
        create(:watchbill_station_assignment, watchbill: watchbill, watchstation: station,
                                             shift: shift, worker: create(:worker, name: name))
      end

      expect(grid_for(watchbill, watchset: watchset).rows)
        .to eq([ [ "Rover", "Ann", "Bo", "Cy" ] ])
    end

    it "fills only the shifts that have an assignment" do
      station = create(:watchstation, name: "Rover", watchset: watchset)
      create(:watchbill_station_assignment, watchbill: watchbill, watchstation: station,
                                           shift: "Swings", worker: create(:worker, name: "Bo"))

      expect(grid_for(watchbill, watchset: watchset).rows)
        .to eq([ [ "Rover", nil, "Bo", nil ] ])
    end
  end

  context "when several stations share a watchbill" do
    it "keeps each station's workers in its own row" do
      rover = create(:watchstation, name: "Rover", watchset: watchset)
      condenser = create(:watchstation, name: "Condenser", watchset: watchset)
      create(:watchbill_station_assignment, watchbill: watchbill, watchstation: rover,
                                           shift: "Days", worker: create(:worker, name: "Ann"))
      create(:watchbill_station_assignment, watchbill: watchbill, watchstation: condenser,
                                           shift: "Days", worker: create(:worker, name: "Bo"))

      expect(grid_for(watchbill, watchset: watchset).rows)
        .to contain_exactly([ "Rover", "Ann", nil, nil ], [ "Condenser", "Bo", nil, nil ])
    end

    it "ignores assignments belonging to stations outside the scope" do
      mine = create(:watchstation, name: "Mine", watchset: watchset)
      theirs = create(:watchstation, name: "Theirs", watchset: create(:watchset))
      create(:watchbill_station_assignment, watchbill: watchbill, watchstation: theirs,
                                           shift: "Days", worker: create(:worker, name: "Elsewhere"))

      rows = grid_for(watchbill, watchset: watchset).rows

      expect(rows).to eq([ [ "Mine", nil, nil, nil ] ])
      expect(mine).to be_persisted
    end
  end

  context "with lots of stations and a full watchbill" do
    it "renders a row for every station" do
      stations = create_list(:watchstation, 40, watchset: watchset)
      stations.each do |station|
        WatchbillStationAssignment.shifts.each_key do |shift|
          create(:watchbill_station_assignment, watchbill: watchbill, watchstation: station,
                                                shift: shift, worker: create(:worker))
        end
      end

      rows = grid_for(watchbill, watchset: watchset).rows

      expect(rows.size).to eq(40)
      expect(rows).to all(satisfy { |row| row.none?(&:nil?) })
    end
  end

  context "when given an unsaved watchbill with no assignments" do
    # What the show page hands the grid when no valid watchbill exists.
    it "renders each station with every shift blank" do
      create(:watchstation, name: "Rover", watchset: watchset)

      expect(grid_for(Watchbill.new(watchset: watchset), watchset: watchset).rows)
        .to eq([ [ "Rover", nil, nil, nil ] ])
    end
  end
end
