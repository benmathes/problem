## Overview

* `solution.rb` is a wrapping script
* `timeline.rb` is the `Timeline` class, where the meat of the algorithm lives
* `recurrence.rb`, `transaction.rb`, `schedule.rb` contain classes for the first class objects in the system.


## Commentary

* 1-3 hours coding/bugfixing the meat, e.g. `Timeline#allocate`: https://github.com/benmathes/problem/blob/master/timeline.rb
* ruby environments can be fickle. I don't know how I found broken state between my package manager and ruby version, but I did, and that added a couple hours. #devops
* I lost 2 hrs debugging the ruby debugger. The debugger fails when the script reads from STDIN.
* The initial estimate of 2-3 hours seems optimistic for 1k lines of commented/tested code.
* maybe I'm slow? My strengths are in problem understanding/scoping/sketching.
* pre primary/secondary incomes. I disregarded this. Intentionally. All income sources should be used to smooth. If this was the real world and secondary sources had more variance, that variance should be used to build predictive cuhions, but not the source of the income.
* If you want insight into my work on this: https://github.com/benmathes/problem/graphs

## Suggestions

* instead of passing in the json as raw `STDIN`, pass a json filename as a command line argument. If the script uses STDIN at all. Shouldn't make a big difference, but turned out to break ruby debugging.

## Running

Rather than have `run.sh` install ruby version managers, package managers, etc. without your consent, here are instructions:

* you need ruby, I recommend rbenv to manage installed ruby versions: https://github.com/rbenv/rbenv
* inside this git root directory:
  * you need bundler (dependency management) `gem install bundler`
  * install the dependencies: `bundle install`

Then you can run `run.sh`, e.g.
* `run.sh < simple.input.json`
* `run.sh < complex.input.json`
* `run.sh < insolvent.input.json`


### Tests

run `ruby -Ilib:test tests.rb`

### Extra Credit

I wanted to _see_ what the smoothing looked like, so I used a ruby gem that outputs chart images: https://github.com/topfunky/gruff

running `./run.sh` outputs `charts.png`
