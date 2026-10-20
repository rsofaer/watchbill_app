class Watchset < ApplicationRecord
  has_many :watchstations
  has_many :qualifications, through: :watchstations
  has_many :workers, through: :qualifications

  def generate_watchbill
    # We want a Watchbill object, not saved
    # For which each watchstation has been assigned a 
    # WatchbillStationAssignment
    solver = Z3::Solver.new

    # To make this happen, we will define sorts
    # WorkerSort
    # QualificationSort
    # WatchstationSort
    # ShiftSort
    if workers.empty? || qualifications.empty? || watchstations.empty?
      return nil
    end
    worker_sort = enum_sort("Workers", workers.distinct)
    qual_sort = enum_sort("Qualifications", qualifications.distinct)
    watch_sort = enum_sort("Watchstations", watchstations)
    shift_sort = Z3::EnumSort.new("Shift", WatchbillStationAssignment.shifts.keys)

    # And functions
    # HasQualification: Worker -> Qualification -> bool
    # RequiresQualification: Watchstation -> Qualification -> bool

    has_qual = Z3::Function("HasQualification", worker_sort, qual_sort, Z3::BoolSort.new)
    requires_qual = Z3::Function("RequiresQualification", watch_sort, qual_sort, Z3::BoolSort.new)
    qualifications.distinct.each do |q|
      workers.distinct.each do |w|
        if w.qualifications.include?(q)
          solver.assert(has_qual[w.z3_id,q.z3_id])
        else
          solver.assert(!has_qual[w.z3_id,q.z3_id])
        end
      end
      watchstations.each do |w|
        if w.qualification == q
          solver.assert(requires_qual[w.z3_id,q.z3_id])
        else
          solver.assert(!requires_qual[w.z3_id,q.z3_id])
        end
      end

    end

    # Then, we define function isAssigned(Worker, Watchstation, Shift)
    # And constrain it with: 
    # 1. A worker assigned to a shift must have the required qualification: isAssigned(wx, wsx, sx) /\ RequiresQualification(wsx, q) -> HasQualification(wx, q)
    # 2. If two workers are assigned to the same shift, they must be the same worker: isAssigned(w1, ws1, s1) /\ isAssigned(w2, ws1, s1) -> w1 = w2
    # 3. If a worker is assigned to two shifts, they must be the same shift: isAssigned(w1, ws1, s1) /\ isAssigned(w1, ws2, s2) -> ws1 = ws2 /\ s1 = s2
    assigned_worker = Z3::Function("IsAssigned", watch_sort, shift_sort, worker_sort)
    
    worker = worker_sort.fresh_var("worker")
    worker2 = worker_sort.fresh_var("worker")
    watch = watch_sort.fresh_var("watch")
    watch2 = watch_sort.fresh_var("watch")
    shift = shift_sort.fresh_var("shift")
    shift2 = shift_sort.fresh_var("shift")
    qual = qual_sort.fresh_var("qual")

    solver.assert(Z3::ForAll([worker, watch, shift, qual], 
      Z3::Implies(Z3::And(assigned_worker[watch, shift] == worker, requires_qual[watch, qual]),
        has_qual[worker, qual])))
    worker = worker_sort.fresh_var("worker")
    worker2 = worker_sort.fresh_var("worker")
    watch = watch_sort.fresh_var("watch")
    watch2 = watch_sort.fresh_var("watch")
    shift = shift_sort.fresh_var("shift")
    shift2 = shift_sort.fresh_var("shift")
    qual = qual_sort.fresh_var("qual")
    solver.assert(Z3::ForAll([worker, worker2, watch, shift, qual],
      Z3::Implies(Z3::And(assigned_worker[watch, shift] == worker, assigned_worker[watch, shift] == worker2),
        worker == worker2)))
    worker = worker_sort.fresh_var("worker")
    worker2 = worker_sort.fresh_var("worker")
    watch = watch_sort.fresh_var("watch")
    watch2 = watch_sort.fresh_var("watch")
    shift = shift_sort.fresh_var("shift")
    shift2 = shift_sort.fresh_var("shift")
    qual = qual_sort.fresh_var("qual")
    solver.assert(Z3::ForAll([worker, watch, watch2, shift, shift2],
      Z3::Implies(Z3::And(assigned_worker[watch, shift] == worker, assigned_worker[watch2, shift2] == worker),
        Z3::And(watch == watch2, shift == shift2))))

    if solver.satisfiable?
      # Evaluate every (station, shift) pair explicitly: func_interp only lists
      # explicit entries and folds one of them into its "else" default value.
      model = solver.model
      bill = Watchbill.new(watchset: self)
      watchstations.each do |station|
        WatchbillStationAssignment.shifts.each_key do |shift|
          worker = model.model_eval(assigned_worker[station.z3_id, shift.to_sym], true)
          worker_id = worker.to_s.split("_").last.to_i
          bill.watchbill_station_assignments.build(watchstation: station, shift: shift, worker_id: worker_id)
        end
      end
      bill
    end
  end

  private

  # Z3 enum sorts are registered process-wide by name, and redeclaring a name
  # with different values raises, so key each sort's name by its contents.
  def enum_sort(name, records)
    values = records.sort_by(&:id).map(&:z3_id)
    Z3::EnumSort.new("#{name}_#{Digest::SHA1.hexdigest(values.join(","))}", values)
  end
end
