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
* to prevent unecessary precision in the smoothing, I put in a `Timeline::SMOOTHING_FUZZINESS` that is an acceptable difference of spend between days.


## where to improve:

* smoothing algo (`Timline#plan_daily_spend`): I'll use the "pushing snow around" analogy to the graph of daily spendable. My code pushes the snow forward through time, e.g.
  * <img to go here>
  * but this requires multiple loops. I can imagine starting from the end and pulling snow forward instead of pushing from the start might not require the outer and inner smoothing loop.
  * A lot of pointers from smoothing windows could be preserved as shortcuts to prevent hidden loops, e.g. storing smoothing window start/end, instead of traversing the full list of income days each time.



## Suggestions

Possible I misread. But here's where I think it can be more clear:

* instead of passing in the json as raw `STDIN`, pass a json filename as a command line argument. If the script uses STDIN at all. Shouldn't make a big difference, but turned out to break ruby debugging.
* the `spendable` key in the output is a little ambiguous. While there is one sentence in the description that asks to minimize spending fluctions, there are still ambiguities.
  * _daily_ spendable until next income?
  * _total_ spendable until next income?
  * _daily_ spendable until next income, _smoothed_? (from UX perspective, should be this)
  * _total_ spendable until next income, _smoothed_? (from problem description seems like you ask for this)
* If the user is thinking in terms of daily spendable, shouldn't the output be days, e.g.:
```json
{
  "days": [
    {
      date: "2016-1-15",
      daily_spendable: 12.50,
      incomes: [
        {
            "type": "income",
            "name": "Starbucks",
            "date": "2016-01-15",
            "amount": 300,
            "daily_spendable": 10.00,
            "allocations": [
                {
                    "name": "Rent",
                    "date": "2016-01-15",
                    "amount": 120.00
                }
            ],
        },
        {
            "type": "income",
            "name": "knitting",
            "date": "2016-01-15",
            "daily_spendable": 2.50,
            "allocations": [
                {
                    "name": "Rent",
                    "date": "2016-01-15",
                    "amount": 10.00
                }
            ],
        },
        ...
      ],
      expenses: [...],
    },
  ]
}
```
You can see this output if you run `./run.sh [-d/--daily] < input.json`


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
