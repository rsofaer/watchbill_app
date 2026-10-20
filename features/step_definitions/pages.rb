When('I am on the watchset page for {string}') do |string|
  visit watchset_path id: Watchset.find_by!(name: string).id
end

Then('I should see a row with {string}') do |string|
  pending
  #expect(page).to have_content(string)
end

Then('I should see {string}.') do |string|
  pending
  #expect(page).to have_content(string)
end

