Feature: Viewing a Watchset
  The watchset page solves for a watchbill and lays it out as one row per
  watchstation, with a column for each of the three shifts.

  # Only one scenario in this file may reach the solver. Z3 registers its enum
  # sorts against the process-wide context by name, and #generate_watchbill
  # always uses the same four names, so a second scenario with a staffed
  # watchset raises Z3::Exception. "No Watchstations" is safe because
  # #generate_watchbill returns early, before it declares any sort.

  Scenario: No Watchstations
    Given a watchset named "Empty" with no watchstations
    When I am on the watchset page for "Empty"
    Then I should see the column headers "Watchstation, Days, Swings, Mids"
    And I should see an empty table.
    And I should see a link to add a watchstation.

  Scenario: With Watchstations
    Given a watchset named "Example" with watchstations "Fire Watch, Control Room Watch"
    And each watchstation has 3 qualified workers
    When I am on the watchset page for "Example"
    Then I should see 2 rows
    And I should see a row with "Fire Watch"
    And I should see a row with "Control Room Watch"
