class Watchset < ApplicationRecord
  has_many :watchstations
  has_many :watchbills
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
    worker_sort = Z3::EnumSort.new("Workers", workers.distinct.map {|x| x.z3_id})
    qual_sort = Z3::EnumSort.new("Qualifications", qualifications.distinct.map {|x| x.z3_id})
    watch_sort = Z3::EnumSort.new("Watchstations", watchstations.map {|x| x.z3_id})
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

    puts solver.check
    if solver.satisfiable?
      # Walking the function's interpretation entry by entry misses whichever
      # slot Z3 leaves to its `else` branch, so ask the model about every slot.
      model = solver.model
      bill = Watchbill::build(watchset: self)
      watchstations.each do |station|
        WatchbillStationAssignment.shifts.each_key do |shift|
          worker = model[assigned_worker[watch_sort[station.z3_id], shift_sort[shift]]]
          worker_id = worker.to_s.split("_").last.to_i
          bill.watchbill_station_assignments.build(watchstation: station, shift: shift, worker_id: worker_id)
        end
      end
      bill
    else
      solver.unsat_core
    end
  end


end
