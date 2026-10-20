# WatchbillApp

This application is for generating watchbills.
A watchbill is an assignment of workers to a set of watchstations needed to operate some plant.
A valid watchbill has one qualified worker per watchbill per shift.

WatchbillApp uses Z3 to find valid sets of qualified workers.

# Test coverage

WatchbillApp has a comprehensive test suite which must be updated along with the app.
In addition, mutant must be run using `bundle exec mutant` to detect weak tests.

Run the app with port 3007 (`./bin/dev`)
