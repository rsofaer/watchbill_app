Feature: Listing Watchbills
  The root page lists every watchset, twenty-five to a page.

  Scenario: No Watchsets
    Given there are no watchsets
    When I am on the watchbill list
    Then I should see the column headers "Name, Created at"
    And I should see an empty table.

  Scenario: A Few Watchsets
    Given a watchset named "Indian Point Normal Operations" with no watchstations
    And a watchset named "Drydock" with no watchstations
    When I am on the watchbill list
    Then I should see 2 rows
    And I should see a row with "Indian Point Normal Operations"
    And I should see a row with "Drydock"

  Scenario: More Watchsets Than Fit On A Page
    Given there are 60 watchsets
    When I am on the watchbill list
    Then I should see 25 rows
    And I should see pagination controls

  Scenario: The Last Page Of Watchsets
    Given there are 60 watchsets
    When I am on page 3 of the watchbill list
    Then I should see 10 rows
