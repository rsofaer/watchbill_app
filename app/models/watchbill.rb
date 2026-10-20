class Watchbill < ApplicationRecord
  belongs_to :watchset
  has_many :watchstations, through: :watchset

  has_many :watchbill_station_assignments, dependent: :destroy
  has_many :workers, through: :watchbill_station_assignments

  accepts_nested_attributes_for :watchbill_station_assignments

  # Checks the bill against the current state of the watchset, workers and
  # qualifications, which may have changed since the bill was saved.
  # Returns a list of human-readable problems; empty if the bill is valid.
  def problems
    problems = []
    assignments = watchbill_station_assignments.to_a
    stations = watchset.watchstations.to_a

    stations.each do |station|
      WatchbillStationAssignment.shifts.each_key do |shift|
        count = assignments.count { |a| a.watchstation_id == station.id && a.shift == shift }
        if count == 0
          problems << "#{station.name} (#{shift}) has no worker assigned."
        elsif count > 1
          problems << "#{station.name} (#{shift}) has #{count} workers assigned."
        end
      end
    end

    assignments.each do |a|
      station = a.watchstation
      if station.nil? || !stations.include?(station)
        problems << "An assignment is for a watchstation that is no longer part of #{watchset.name}."
      elsif a.worker.nil?
        problems << "#{station.name} (#{a.shift}) is assigned to a worker who no longer exists."
      elsif !a.worker.qualifications.include?(station.qualification)
        problems << "#{a.worker.name} is not qualified as #{station.qualification.name} for #{station.name} (#{a.shift})."
      end
    end

    assignments.group_by(&:worker_id).each do |_, worker_assignments|
      worker = worker_assignments.first.worker
      if worker && worker_assignments.size > 1
        problems << "#{worker.name} is assigned to #{worker_assignments.size} watches."
      end
    end

    problems
  end

  def valid_watchbill?
    problems.empty?
  end
end
