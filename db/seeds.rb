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
  w = Worker.build()
  w.name = Faker::Name.name
  if Worker.exists?(name: w.name)
    next
  end
  quals.each do |q|
    if Faker::Boolean.boolean(true_ratio: q[1])
      w.qualifications << q[2]
    end
  end
  w.save!
end

quals.each do |qt|
  q = qt[2]
  while q.workers.count < 4
    q.workers << Worker.find_by!(id: Faker::Number.within(range: Worker.count))
  end
  q.save!
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

watchset = Watchset.create!(name: "Indian Point Normal Operations")
watchstations.each do |station|
  watchstation = Watchstation.create!(name: station[0], qualification: Qualification.find_by_name!(station[1]), watchset: watchset)
end

