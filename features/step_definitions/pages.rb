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
  pending "the watchset page has no link for adding a watchstation yet"
end
