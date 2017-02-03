## Even Financial Planner

Money is hard. You need to use income that arrives on a certain schedule to pay bills that are due on different schedules. Some bills are large, and some are small. Big bills might be lumped together, leaving you with little money left to spend if you hadn't planned ahead. At Even, we want to take on the burden of planning for your biggest bills, so that you are left with a steady flow of discretionary spending and can stress less about money.

### Your task

Given information about future incomes and expenses, build a financial planner. Specifically, plan how money from paydays will be allocated:

* Map incomes to expenses such that all bills are provisioned for before they are due.
* Maximize the stability of leftover, "discretionary" income from the primary income source.
* Be aware that you are working for _real people_, so your output should be **intuitive**, not just mathematically sound.

**Notes:**

* Our customers frequently work multiple jobs, so you'll need to support mapping funds from one or more incomes.
* You can expect one income to be identified as the "primary" income -- stable discretionary income should be allocated on this schedule. Secondary incomes can be fully allocated to expenses.
* Schedules vary widely: some are one-time-only; some are defined on an interval basis (e.g. every other Friday) while others are defined on a monthly basis (e.g. the 1st and 15th of each month).
* If an income and expense occur on the same day you are permitted to use the newly received funds to meet the same-day expense.
* Insolvency: not having enough funds to meet an expense is possible and you must handle it by emitting an error.
* We've only given you a subset of our test cases. Your algorithm should work well in tight or unconventional situations. Part of the exercise is discovering where things might break and articulating cases for them.

### What are we looking for?

Your goals are twofold:

* Show that you are capable of quickly solving a problem in an unfamiliar domain.
* Demonstrate what you consider to be a clean, understandable, and maintainable solution.

We're hoping to see what you believe to be a "production-quality" submission. Where that isn't possible, a comment in the source code should be more than enough for us to understand what you're thinking.

### Input

Your program will accept a JSON map via STDIN that contains data about the customer. Example:

```json
{
    "incomes": [
        {
            "name": "Starbucks",
            "amount": 200.00,
            "type": "PRIMARY",
            "schedule": {
                "type": "interval",
                "period": 14,
                "start": "2016-01-01"
            }
        }
    ],
    "expenses": [
        {
            "name": "Rent",
            "amount": 100.00,
            "schedule": {
                "type": "interval",
                "period": 14,
                "start": "2016-01-01"
            }
        }
    ]
}
```

* **Note**: Your submission should assume that time begins on `2016-01-01` and ends on `2017-01-01`
* We support a variety of schedules. You'll want to take a look at `complex.input.json` to get a sense for the other types we might send your way.

### Output

We expect JSON over STDOUT that describes a time series of income and expense events. On each income, you will specify the funds set aside for future expenses. All leftover funds must be accounted for in the "spendable" key. You can assume that customers will spend all of their spendable funds, so stability is important.

```json
{
    "events": [
        {
            "type": "income",
            "name": "Starbucks",
            "date": "2016-01-15",
            "allocations": [
                {
                    "name": "Rent",
                    "date": "2016-01-15",
                    "amount": 120.00
                }
            ],
            "spendable": 80.00,
        },
        {
            "type": "expense",
            "name": "Rent",
            "date": "2016-01-15",
            "sources": [
                {
                    "name": "Starbucks",
                    "date": "2016-01-15",
                    "amount": 120.00
                }
            ]
        }
        // ... etc ...
    ]
}
```

#### Insolvency

You must detect and handle this by emitting the following output:

```json
{
    "error": "Insolvent"
}
```

### Deliverable

You are welcome to implement your solution in the language of choice.

We expect a ZIP archive containing the following:

* `run.sh` file at the root of the archive that runs your application
* Written summary of your approach, and avenues for future development
* Source code
* Test cases
