class Watchbill < ApplicationRecord
  belongs_to :watchset
  has_many :watchstations, through: :watchset

  has_many :watchbill_station_assignments, dependent: :destroy
  has_many :workers, through: :watchbill_station_assignments

  accepts_nested_attributes_for :watchbill_station_assignments

  # Everything that keeps this watchbill from staffing its watchset, checked
  # against the watchset and roster as they stand now. Qualifications and
  # watchstations can change after a watchbill is saved, so a bill that was
  # valid when it was saved can stop being valid later.
  def staffing_problems
    assignments = watchbill_station_assignments
    problems = []

    assignments.each do |assignment|
      station = assignment.watchstation
      worker = assignment.worker
      if station.watchset != watchset
        problems << "#{station.name} is not a watchstation in #{watchset.name}"
      end
      unless worker.qualifications.include?(station.qualification)
        problems << "#{worker.name} is not qualified for #{station.name} (#{assignment.shift})"
      end
    end

    assignments.group_by { |a| [ a.watchstation_id, a.shift ] }.each_value do |slot|
      next if slot.one?
      problems << "#{slot.first.watchstation.name} has more than one worker on #{slot.first.shift}"
    end

    assignments.group_by(&:worker_id).each_value do |watches|
      next if watches.one?
      problems << "#{watches.first.worker.name} is assigned to more than one watch"
    end

    filled = assignments.map { |a| [ a.watchstation_id, a.shift ] }
    watchstations.each do |station|
      WatchbillStationAssignment.shifts.each_key do |shift|
        next if filled.include?([ station.id, shift ])
        problems << "#{station.name} has nobody on #{shift}"
      end
    end

    problems
  end

  def properly_staffed?
    staffing_problems.empty?
  end
end
