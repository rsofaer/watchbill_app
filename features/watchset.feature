Feature: Viewing a Watchset
    Scenario: No Watchstations
	Given a watchset named "Empty" with no watchstations
	When I am on the watchset page for "Empty"
	Then I should see an empty table.
	And I should see a link to add a watchstation.

    Scenario: With Watchstations
	Given a watchset named "Example" with watchstations "Fire Watch, Control Room Watch"
	When I am on the watchset page for "Example"
	Then I should see a row with "Fire Watch"
	And I should see a row with "Control Room Watch"


