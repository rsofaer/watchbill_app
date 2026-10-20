require "rails_helper"

RSpec.describe Watchset, "#generate_watchbill against the solver" do
  let(:watchset) { create(:watchset, name: "Indian Point Normal Operations") }
  let(:shifts) { WatchbillStationAssignment.shifts.keys }

  def staff(watchset, station_count:, workers_per_qualification:)
    Array.new(station_count) do |i|
      qualification = create(:qualification, name: "Qualification #{i}")
      create_list(:worker, workers_per_qualification, qualifications: [ qualification ])
      create(:watchstation, name: "Station #{i}", watchset: watchset, qualification: qualification)
    end
  end

  context "when every station has a qualified worker for each shift" do
    let!(:stations) { staff(watchset, station_count: 2, workers_per_qualification: 3) }

    it "builds an unsaved watchbill whose every assignment is qualified and unique" do
      watchbill = watchset.reload.generate_watchbill

      aggregate_failures do
        expect(watchbill).to be_a(Watchbill)
        expect(watchbill).not_to be_persisted
        expect(watchbill.watchset).to eq(watchset)
        expect(Watchbill.count).to eq(0)
        expect(WatchbillStationAssignment.count).to eq(0)

        assignments = watchbill.watchbill_station_assignments

        # Every station is filled on every shift, exactly once.
        expect(assignments.map { |a| [ a.watchstation, a.shift ] })
          .to match_array(stations.product(shifts))

        # The constraint that matters: nobody stands a watch they are not qualified for.
        assignments.each do |assignment|
          expect(assignment.worker.qualifications)
            .to include(assignment.watchstation.qualification),
                "#{assignment.worker.name} is not qualified for #{assignment.watchstation.name}"
        end

        # No worker stands two watches.
        expect(assignments.map(&:worker_id).uniq.size).to eq(assignments.size)
      end
    end

    it "can be solved again in the same process" do
      expect(watchset.generate_watchbill.watchbill_station_assignments.size).to eq(6)
      expect(watchset.generate_watchbill.watchbill_station_assignments.size).to eq(6)
    end
  end

  it "solves a second watchset with a different roster in the same process" do
    staff(watchset, station_count: 1, workers_per_qualification: 3)
    other = create(:watchset)
    staff(other, station_count: 2, workers_per_qualification: 4)

    expect(watchset.generate_watchbill.watchbill_station_assignments.size).to eq(3)
    expect(other.generate_watchbill.watchbill_station_assignments.size).to eq(6)
  end

  it "uses a worker qualified for several stations only once" do
    qualification = create(:qualification)
    stations = create_list(:watchstation, 2, watchset: watchset, qualification: qualification)
    create_list(:worker, 6, qualifications: [ qualification ])

    assignments = watchset.generate_watchbill.watchbill_station_assignments

    expect(assignments.map { |a| [ a.watchstation, a.shift ] }).to match_array(stations.product(shifts))
    expect(assignments.map(&:worker_id).uniq.size).to eq(6)
  end

  it "returns nil when there are too few qualified workers to cover every shift" do
    staff(watchset, station_count: 1, workers_per_qualification: 2)

    expect(watchset.generate_watchbill).to be_nil
  end

  it "does not write to stdout" do
    staff(watchset, station_count: 1, workers_per_qualification: 3)

    expect { watchset.generate_watchbill }.not_to output.to_stdout
  end
end
