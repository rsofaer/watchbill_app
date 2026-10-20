Feature: Editing Watchsets
  Watchsets are created from the watchbill list, and their watchstations are
  added and removed on the watchset's edit page. Each watchstation requires a
  qualification.

  Scenario: Creating A Watchset
    Given there are no watchsets
    When I am on the watchbill list
    And I follow "New watchset"
    And I fill in "Name" with "Drydock"
    And I press "Create watchset"
    Then I should see "Watchset created."
    And I should see "This watchset has no watchstations yet."

  Scenario: Creating A Watchset Without A Name
    When I am on the watchbill list
    And I follow "New watchset"
    And I press "Create watchset"
    Then I should see "Name can't be blank"

  Scenario: Adding A Watchstation
    Given a watchset named "Drydock" with no watchstations
    And a qualification named "Firefighter"
    When I am on the watchbill list
    And I follow "Edit"
    And I fill in "Name" with "Fire Watch"
    And I select "Firefighter" from "Required qualification"
    And I press "Add watchstation"
    Then I should see "Added Fire Watch."
    And I should see the watchstation "Fire Watch" requiring "Firefighter"

  Scenario: Adding A Watchstation Without A Qualification
    Given a watchset named "Drydock" with no watchstations
    And a qualification named "Firefighter"
    When I am on the edit page for "Drydock"
    And I fill in "Name" with "Fire Watch"
    And I press "Add watchstation"
    Then I should see "Qualification must exist"
    And I should see "This watchset has no watchstations yet."

  Scenario: Removing A Watchstation
    Given a watchset named "Example" with watchstations "Fire Watch, Control Room Watch"
    When I am on the edit page for "Example"
    And I press "Remove" for the watchstation "Fire Watch"
    Then I should see "Removed Fire Watch."
    And I should see the watchstation "Control Room Watch" requiring "Control Room Watch Qualification"
    And I should not see the watchstation "Fire Watch"

  Scenario: Reaching The Edit Page From The Watchset Page
    Given a watchset named "Empty" with no watchstations
    When I am on the watchset page for "Empty"
    And I follow "Add or remove watchstations"
    Then I should see "This watchset has no watchstations yet."
