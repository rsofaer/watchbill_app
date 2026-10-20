# Stands in for the save button so these scenarios stay clear of the solver,
# which can only run once per process.
Given('a saved watchbill for {string} that staffs every watch') do |name|
  watchset = Watchset.find_by!(name: name)
  bill = watchset.watchbills.create!
  watchset.watchstations.each do |station|
    workers = station.qualification.workers.to_a
    WatchbillStationAssignment.shifts.each_key.with_index do |shift, i|
      bill.watchbill_station_assignments.create!(watchstation: station, shift: shift, worker: workers[i])
    end
  end
end

Given('the worker on {string} {word} loses their qualification') do |station_name, shift|
  assignment = WatchbillStationAssignment.joins(:watchstation)
    .find_by!(watchstations: { name: station_name }, shift: shift)
  assignment.worker.worker_qualifications
    .where(qualification: assignment.watchstation.qualification).destroy_all
end

When('I am on the saved watchbills page for {string}') do |name|
  visit watchset_watchbills_path(Watchset.find_by!(name: name))
end

When('I follow the first saved watchbill') do
  within("table.datagrid-table tbody") { first("a").click }
end

When('I save the watchbill') do
  click_button "Save this watchbill"
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should see that the watchbill is valid') do
  expect(page).to have_css(".watchbill-status", text: "This watchbill is valid.")
end

Then('I should see that the watchbill is not valid') do
  expect(page).to have_css(".watchbill-status", text: "This watchbill is not valid.")
end
