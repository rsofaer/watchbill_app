require "rails_helper"

# Z3 registers an enum sort by name against the process-wide context, and
# refuses to declare the same name twice with different values. #generate_watchbill
# names its sorts "Workers", "Qualifications", "Watchstations" and "Shift", and
# fills them from the record ids it finds, so the second call in a process with a
# different roster raises Z3::Exception. Clearing the gem's own registry does not
# help -- Z3 itself rejects the redeclaration.
#
# So the whole suite gets exactly one trip through the solver, and it lives
# here. Everything else about the method -- the guard clauses it returns nil
# from, and the grid's handling of each shape it returns -- is covered without
# a solver run in watchset_spec.rb, watchset_grid_spec.rb and the request specs.
RSpec.describe "Watchset#generate_watchbill against the solver" do
  let(:station_count) { 2 }
  let(:workers_per_qualification) { 3 } # one per shift, the minimum that solves

  before do
    if Z3::EnumSort.declared?("Workers")
      raise "Z3's \"Workers\" enum sort is already declared in this process. " \
            "#generate_watchbill can only run once per process -- see the comment " \
            "at the top of #{__FILE__}."
    end
  end

  let(:watchset) { create(:watchset, name: "Indian Point Normal Operations") }

  let!(:stations) do
    Array.new(station_count) do |i|
      qualification = create(:qualification, name: "Qualification #{i}")
      create_list(:worker, workers_per_qualification, qualifications: [ qualification ])
      create(:watchstation, name: "Station #{i}", watchset: watchset, qualification: qualification)
    end
  end

  it "builds an unsaved watchbill whose every assignment is qualified and unique" do
    watchbill = watchset.reload.generate_watchbill

    aggregate_failures do
      expect(watchbill).to be_a(Watchbill)
      expect(watchbill).not_to be_persisted
      expect(watchbill.watchset).to eq(watchset)
      expect(Watchbill.count).to eq(0)
      expect(WatchbillStationAssignment.count).to eq(0)

      assignments = watchbill.watchbill_station_assignments
      expect(assignments).not_to be_empty
      expect(assignments.size).to be <= station_count * WatchbillStationAssignment.shifts.size

      expect(assignments.map(&:watchstation)).to all(be_in(stations))
      expect(assignments.map(&:shift)).to all(be_in(WatchbillStationAssignment.shifts.keys))

      # The constraint that matters: nobody stands a watch they are not qualified for.
      assignments.each do |assignment|
        expect(assignment.worker.qualifications)
          .to include(assignment.watchstation.qualification),
              "#{assignment.worker.name} is not qualified for #{assignment.watchstation.name}"
      end

      # No worker stands two watches, and no station-and-shift is double-filled.
      expect(assignments.map(&:worker_id).uniq.size).to eq(assignments.size)
      expect(assignments.map { |a| [ a.watchstation_id, a.shift ] }.uniq.size).to eq(assignments.size)
    end
  end
end
