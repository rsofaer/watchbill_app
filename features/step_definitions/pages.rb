When('I am on the watchset page for {string}') do |name|
  visit watchset_path id: Watchset.find_by!(name: name).id
end

When('I am on the watchbill list') do
  visit watchsets_path
end

When('I am on page {int} of the watchbill list') do |page|
  visit watchsets_path(page: page)
end

Then('I should see a row with {string}') do |text|
  expect(page).to have_css("table.datagrid-table tbody td", text: text)
end

Then('I should see an empty table.') do
  expect(page).to have_css("table.datagrid-table")
  expect(page).to have_css("table.datagrid-table td.datagrid-no-results")
end

Then('I should see {int} rows') do |count|
  expect(page).to have_css("table.datagrid-table tbody tr", count: count)
end

Then('I should see the column headers {string}') do |headers|
  headers.split(",").map(&:strip).each do |header|
    expect(page).to have_css("table.datagrid-table thead th", text: header)
  end
end

Then('I should see pagination controls') do
  expect(page).to have_css("nav.pagination, .pagination")
end

Then('I should see a link to add a watchstation.') do
  expect(page).to have_link("Add or remove watchstations")
end

When('I am on the edit page for {string}') do |name|
  visit edit_watchset_path(Watchset.find_by!(name: name))
end

When('I follow {string}') do |link|
  click_link link
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I select {string} from {string}') do |option, field|
  select option, from: field
end

When('I press {string}') do |button|
  click_button button
end

When('I press {string} for the watchstation {string}') do |button, name|
  within("table.watchstations tr", text: name) { click_button button }
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should see the watchstation {string} requiring {string}') do |name, qualification|
  row = find("table.watchstations tbody tr", text: name)
  expect(row).to have_css("td", text: qualification)
end

Then('I should not see the watchstation {string}') do |name|
  expect(page).not_to have_css("table.watchstations tbody tr", text: name)
end

When('I am on the worker list') do
  visit workers_path
end

When('I am on the new worker page') do
  visit new_worker_path
end

When('I am on the worker page for {string}') do |name|
  visit worker_path(Worker.find_by!(name: name))
end
