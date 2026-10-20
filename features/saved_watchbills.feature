Feature: Saved Watchbills
  A watchbill saved from a watchset page can be looked at again later, and
  says whether it still staffs its watchset with the roster as it is now.

  Background:
    Given a watchset named "Example" with watchstations "Fire Watch, Control Room Watch"
    And each watchstation has 3 qualified workers
    And a saved watchbill for "Example" that staffs every watch

  Scenario: Listing Saved Watchbills
    When I am on the saved watchbills page for "Example"
    Then I should see the column headers "Watchbill, Saved on, Valid"
    And I should see 1 rows
    And I should see a row with "Yes"

  Scenario: Viewing A Valid Watchbill
    When I am on the saved watchbills page for "Example"
    And I follow the first saved watchbill
    Then I should see that the watchbill is valid
    And I should see a row with "Fire Watch"
    And I should see a row with "Control Room Watch"

  Scenario: A Watchbill That Is No Longer Valid
    Given the worker on "Fire Watch" Days loses their qualification
    When I am on the saved watchbills page for "Example"
    Then I should see a row with "No"
    When I follow the first saved watchbill
    Then I should see that the watchbill is not valid
    And I should see "is not qualified for Fire Watch (Days)"
