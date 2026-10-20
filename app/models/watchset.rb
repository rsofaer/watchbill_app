class Watchset < ApplicationRecord
  has_many :watchstations
  has_many :watchbills
  has_many :qualifications, through: :watchstations
  has_many :workers, through: :qualifications

  validates :name, presence: true

  # Returns an unsaved Watchbill in which every watchstation has a qualified
  # worker on every shift, or nil when there is nothing to solve or no such
  # assignment exists.
  def generate_watchbill
    solver = Z3::Solver.new

    # To make this happen, we will define sorts
    # WorkerSort
    # QualificationSort
    # WatchstationSort
    # ShiftSort
    if workers.empty? || qualifications.empty? || watchstations.empty?
      return nil
    end
    all_workers = workers.distinct.to_a
    all_quals = qualifications.distinct.to_a
    all_stations = watchstations.to_a
    shifts = WatchbillStationAssignment.shifts.keys

    # Z3 enum sorts are declared process-wide and cannot be redeclared with
    # different values, so each solve gets its own sort names.
    suffix = SecureRandom.hex(8)
    worker_sort = Z3::EnumSort.new("Workers_#{suffix}", all_workers.map(&:z3_id))
    qual_sort = Z3::EnumSort.new("Qualifications_#{suffix}", all_quals.map(&:z3_id))
    watch_sort = Z3::EnumSort.new("Watchstations_#{suffix}", all_stations.map(&:z3_id))
    shift_sort = Z3::EnumSort.new("Shift_#{suffix}", shifts)

    # And functions
    # HasQualification: Worker -> Qualification -> bool
    # RequiresQualification: Watchstation -> Qualification -> bool

    has_qual = Z3::Function("HasQualification_#{suffix}", worker_sort, qual_sort, Z3::BoolSort.new)
    requires_qual = Z3::Function("RequiresQualification_#{suffix}", watch_sort, qual_sort, Z3::BoolSort.new)
    all_quals.each do |q|
      all_workers.each do |w|
        if w.qualifications.include?(q)
          solver.assert(has_qual[w.z3_id, q.z3_id])
        else
          solver.assert(!has_qual[w.z3_id, q.z3_id])
        end
      end
      all_stations.each do |w|
        if w.qualification == q
          solver.assert(requires_qual[w.z3_id, q.z3_id])
        else
          solver.assert(!requires_qual[w.z3_id, q.z3_id])
        end
      end
    end

    # Then, we define function AssignedWorker(Watchstation, Shift) -> Worker,
    # which by being a function fills every station-and-shift with exactly one
    # worker, and constrain it with:
    # 1. A worker assigned to a shift must have the required qualification:
    #    AssignedWorker(wsx, sx) = wx /\ RequiresQualification(wsx, q) -> HasQualification(wx, q)
    # 2. A worker stands at most one watch:
    #    AssignedWorker(ws1, s1) = w /\ AssignedWorker(ws2, s2) = w -> ws1 = ws2 /\ s1 = s2
    assigned_worker = Z3::Function("AssignedWorker_#{suffix}", watch_sort, shift_sort, worker_sort)

    worker = worker_sort.fresh_var("worker")
    watch = watch_sort.fresh_var("watch")
    watch2 = watch_sort.fresh_var("watch")
    shift = shift_sort.fresh_var("shift")
    shift2 = shift_sort.fresh_var("shift")
    qual = qual_sort.fresh_var("qual")

    solver.assert(Z3::ForAll([ worker, watch, shift, qual ],
      Z3::Implies(Z3::And(assigned_worker[watch, shift] == worker, requires_qual[watch, qual]),
        has_qual[worker, qual])))
    solver.assert(Z3::ForAll([ worker, watch, watch2, shift, shift2 ],
      Z3::Implies(Z3::And(assigned_worker[watch, shift] == worker, assigned_worker[watch2, shift2] == worker),
        Z3::And(watch == watch2, shift == shift2))))

    return nil unless solver.satisfiable?

    # Evaluate every station-and-shift rather than walking the function's
    # interpretation, whose `else` branch covers slots it lists no entry for.
    model = solver.model
    workers_by_id = all_workers.index_by(&:z3_id)
    bill = Watchbill.build(watchset: self)
    all_stations.each do |station|
      shifts.each do |shift_name|
        value = model.model_eval(assigned_worker[station.z3_id, shift_name], true).value
        bill.watchbill_station_assignments.build(watchstation: station, shift: shift_name, worker: workers_by_id.fetch(value))
      end
    end
    bill
  end
end
