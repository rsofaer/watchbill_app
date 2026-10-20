Given('a watchset named {string} with no watchstations') do |name|
  Watchset.create!(name: name)
end

Given('a watchset named {string} with watchstations {string}') do |name, station_names|
  watchset = Watchset.create!(name: name)
  station_names.split(",").map(&:strip).each do |station_name|
    qualification = Qualification.find_or_create_by!(name: "#{station_name} Qualification")
    watchset.watchstations.create!(name: station_name, qualification: qualification)
  end
end

# The watchset page solves for a watchbill before it renders, and the solver
# treats every station-and-shift as a slot it must fill from a distinct
# qualified worker. A station with fewer than three qualified workers makes the
# problem unsatisfiable, and the page fails rather than rendering a partial
# watchbill -- so a scenario that wants to see stations has to staff them.
Given('each watchstation has {int} qualified workers') do |count|
  Watchstation.find_each do |station|
    count.times do
      worker = Worker.create!(name: Faker::Name.unique.name)
      worker.qualifications << station.qualification
    end
  end
end

Given('there are {int} watchsets') do |count|
  count.times { |i| Watchset.create!(name: "Watchset #{format('%03d', i + 1)}") }
end

Given('there are no watchsets') do
  Watchset.delete_all
end
