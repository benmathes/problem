### Overview

* `solution.rb` is a wrapping script
* `timeline.rb` is the `Timeline` class, where the meat of the algorithm lives
* `recurrence.rb`, `transaction.rb`, `schedule.rb` contain classes for the first class objects in the system.


## Commentary

* 1-3 hours spent actually coding/bugfixing the meat, e.g. `Timeline#allocate`: https://github.com/benmathes/problem/blob/master/timeline.rb
* ruby environments can be pretty fickle. I don't know how I got into a broken state between my package manager and ruby version, but I did, and that added a couple hours.
* the ruby debugger would not work. I didn't figure this out for about 2-3 hours. Turns out the debugger doesn't work when reading from STDIN, as this project requires.
* Your initial estimate of 2-3 hours seems awfully optimistic given (1) setting up scaffolding, (2) writing tests, (3) complexity of smoothing, etc.
* maybe I'm slow? My strengths are in initial problem understanding/sketching of solutions. Bit-bumming (e.g. off-by-one errors) is not my strong point.

### Running

Rather than have `run.sh` install ruby version managers, package managers, etc. without your consent, here are instructions:

* you need ruby, I recommend rbenv: https://github.com/rbenv/rbenv
* and ruby gems (comes with ruby)
* and bundler `$gitRootDir/gem install bundler`
* install the bundle: `$gitRootDir/bundle install`

Then you can run `run.sh`, e.g.

* `run.sh < simple.input.json`
* `run.sh < complex.input.json`
* `run.sh < insolvent.input.json`
