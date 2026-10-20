Feature: Managing Workers
  Workers and their qualifications can be maintained from the browser.

  Scenario: Adding A Worker
    When I am on the worker list
    And I follow "Add worker"
    And I fill in "Name" with "Alice"
    And I press "Add worker"
    Then I should see "Added Alice."
    And I should see "No qualifications."

  Scenario: Adding A Worker Without A Name
    When I am on the new worker page
    And I press "Add worker"
    Then I should see "Name can't be blank"

  Scenario: Adding And Removing A Qualification
    Given a qualification named "Fire Watch"
    And a worker named "Alice"
    When I am on the worker page for "Alice"
    And I select "Fire Watch" from "worker_qualification_qualification_id"
    And I press "Add qualification"
    Then I should see "Added Fire Watch."
    When I press "Remove"
    Then I should see "Removed Fire Watch."
    And I should see "No qualifications."

  Scenario: Listing Workers
    Given a qualification named "Fire Watch"
    And a worker named "Alice" qualified as "Fire Watch"
    And a worker named "Bob"
    When I am on the worker list
    Then I should see 2 rows
    And I should see a row with "Alice"
    And I should see a row with "Fire Watch"
