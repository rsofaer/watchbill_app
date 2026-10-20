# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
Faker::Config.random = Random.new(43)

quals = [
  ["Shift Supervisor",0.02], 
  ["Mechanical Supervisor",0.04],
  ["Turbine Mechanic",0.15],
  ["Condenser Mechanic",0.2],
  ["Fire Watch", 0.9], 
  ["Auxiliary Mechanic", 0.2], 
  ["Electrical Operator", 0.2],
  ["Reactor Operator", 0.2],
]

quals.each do |q|
  qual = Qualification.find_or_create_by!(name: q[0])
  q << qual
end

200.times do
  # Draw every random value before checking for an existing worker, so the
  # seeded sequence (and thus the generated workers) is the same on every run
  name = Faker::Name.name
  worker_quals = quals.select { |q| Faker::Boolean.boolean(true_ratio: q[1]) }.map { |q| q[2] }
  next if Worker.exists?(name: name)
  Worker.create!(name: name, qualifications: worker_quals)
end

watchstations = [
  ["North Turbines", "Turbine Mechanic"],
  ["South Turbines", "Turbine Mechanic"],
  ["Condenser", "Condenser Mechanic"],
  ["Aux", "Auxiliary Mechanic"],
  ["Rover", "Fire Watch"],
  ["Shift Sup", "Shift Supervisor"],
  ["Mech Sup", "Mechanical Supervisor"],
  ["Reactor Operator", "Reactor Operator"],
  ["Reactor Technician", "Reactor Operator"],
  ["Electrician", "Electrical Operator"],
]

# Each station needs a distinct qualified worker on every shift
shift_count = WatchbillStationAssignment.shifts.size
quals.each do |qt|
  q = qt[2]
  needed = watchstations.count { |station| station[1] == q.name } * shift_count + 1
  while q.workers.count < needed
    q.workers << Worker.where.not(id: q.workers).order(:id).offset(Faker::Number.between(from: 0, to: Worker.count - q.workers.count - 1)).first
  end
end

watchset = Watchset.find_or_create_by!(name: "Indian Point Normal Operations")
watchstations.each do |station|
  Watchstation.find_or_create_by!(name: station[0], qualification: Qualification.find_by_name!(station[1]), watchset: watchset)
end
