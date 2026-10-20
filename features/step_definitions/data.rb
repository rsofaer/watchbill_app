
Given('a watchset named {string} with no watchstations') do |string|
  Watchset.create!(name: string)
end

Given('a watchset named {string} with watchstations {string}') do |string, string2|
  pending
  # ws = Watchset.create!(name: string)
  # stations = string2.split(",")
  # stations.each do |s|
  #   q = Qualification.find_or_create_by!(name: s)
  #   wss = ws.watchstations.create!(qualification: q)
  # end
end

