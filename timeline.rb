# A Timeline
# has many incomes, expenses
# stores an internal timeline, generated from the periodic incomes/expenses
# answers questions like: is is solvent? What's the daily allowable spending money?
class Timeline
  attr_accessor :incomes, :expenses, :timeline, :start, :end, :stats

  def initialize(incomes:, expenses:)
    @stats = {
      income: {
        total: nil,
        avg: nil
      },
      expenses: {
        total: nil,
        avg: nil
      }
    }
    @solvent = nil
    @start = START_DATE
    @end = END_DATE
    @incomes = incomes.map do |income|
      Income.new(
        timeline: self,
        name: income["name"],
        amount: income["amount"],
        type: income["type"],
        schedule: income["schedule"])
    end
    @expenses = expenses.map do |expense|
      Expense.new(
        timeline: self,
        name: expense["name"],
        amount: expense["amount"],
        type: expense["type"],
        schedule: expense["schedule"])
    end
    self.generate
    @planned = []
  end

  def generate
    # @timeline is an array indexed on day of the year
    # where we will mark all the incomes/expenses.
    # As per problem definition, incomes go before expenses on a day
    # e.g. @timeline[0] = [income, expense]
    # TODO: make this a sparse-er data store.
    return @timeline unless @timeline.nil?
    @timeline = []

    # TODO: we put income before expenses on each day on purpose. That's part of the assumption.
    # a less brittle approach would be to enforce the order in some kind of date.get_transactions()
    @incomes.each do |income|
      transactions = income.transactions(timeline_start: self.start, timeline_end: self.end)
      transactions.each do |transaction|
        if @timeline[transaction.date.yday].nil?
          @timeline[transaction.date.yday] = []
        end
        @timeline[transaction.date.yday].push transaction
      end
    end
    @expenses.each do |expense|
      transactions = expense.transactions(timeline_start: self.start, timeline_end: self.end)
      transactions.each do |transaction|
        if @timeline[transaction.date.yday].nil?
          @timeline[transaction.date.yday] = []
        end
        @timeline[transaction.date.yday].push transaction
      end
    end
    return @timeline
  end


  # returns the flattened list of transactions for the year,
  # removing nil days (i.e. no transactions)
  # e.g. [[income, expense], nil, [income]] -> [income, expense, income]
  def flattened
    return @flattened unless @flattened.nil?
    @flattened = []
    @timeline.each do |days_transactions|
      next if days_transactions.try(:length) == 0 or days_transactions.nil?
      days_transactions.each do |transaction|
        @flattened.push transaction
      end
    end
    return @flattened
  end


  # runs through the timeline's transactions and calculates some general stats
  def calc_stats
    running_total = 0
    total_income = 0
    total_expenses = 0
    flattened.each do |transaction|
      running_total += transaction.amount
      puts "total: #{running_total}, on #{transaction.date} for #{transaction.amount} from #{transaction.recurrence.name}" if VERBOSE
      if transaction.income?
        total_income += transaction.amount
      end
      if transaction.expense?
        total_expenses += transaction.amount.abs
      end
      if running_total < 0
        @solvent = false
      end
    end
    @stats[:income][:total] = total_income
    @stats[:income][:avg] = total_income/(@end - @start - 1)
    @stats[:expenses][:total] = total_expenses
    @stats[:expenses][:avg] = total_expenses/(@end - @start - 1)
    @stats[:avg] = @stats[:income][:avg] - @stats[:expenses][:avg]
    @solvent = true if @solvent.nil?
  end


  def solvent?
    calc_stats if @solvent.nil?
    return @solvent
  end

  def to_s
    "<Timeline, #{@stats}>"
  end


  def inspect
    "<Timeline, #{@stats}>"
  end


  def plan!
    allocate!
    plan_daily_spend!
    return @planned
  end

  private

  def allocate!
    # Go backwards to find money to cover expenses. There could be a more mathematically clean
    # way to do this. but the algorithm should be:
    # 1) simple: easy to prove it will never ruin the customer
    # 2) simple: easy to trust by the end user!
    # 3) understandable: smooth with locality
    reversed = flattened.reverse
    reversed.each_with_index do |expense, i|
      # actually iterating over all txns, but only care about expenses.
      # makes later code more readable, expense vs transaction
      next unless expense.expense?
      puts "finding source for #{expense.recurrence.name} on #{expense.date}. #{expense.unsourced} of #{expense.amount.abs} unsourced" if VERBOSE

      # go back in time to find the covering income
      reversed[i..-1].each_with_index do |income|
        break if expense.sourced?
        # actually iterating over all txns, but only care about expenses.
        # makes later code more readable, expense vs transaction
        next unless income.income?
        next if income.allocated?
        puts "  found income: #{income.recurrence.name} on #{income.date}. #{income.unallocated} of #{income.amount} unallocated" if VERBOSE

        if expense.unsourced <= income.unallocated
          allocation_amount = expense.unsourced
          puts "     and #{allocation_amount} of #{income.unallocated} unallocated covers remaiing #{expense.unsourced} expense " if VERBOSE
        else
          allocation_amount = income.unallocated
          puts "     but #{allocation_amount} unallocated is less than #{expense.unsourced} remaining " if VERBOSE
        end

        # TODO: we drop out of the world of class instances to raw hashes here for expediency.
        # A more-pure approach would be: have Allocation and Source as a class, which wraps
        # around the allocated/sourced Transactions. Similar to a many-to-many table in SQL
        income.allocations.push({
          name: expense.recurrence.name,
          date: expense.date,
          amount: allocation_amount
        })
        expense.sources.push({
          name: income.recurrence.name,
          date: income.date,
          amount: allocation_amount
        })
        # after allocationg the prior txn, bring down spendable
        income.spendable = (income.spendable || income.amount) - allocation_amount

        # if we are solvent this shouldn't happen -- sanity check
        if income.spendable < 0
          throw Error("Should never allocate more than amount of income transaction.")
        end
      end
    end
    @planned = reversed.reverse
  end


  def plan_daily_spend!

  end


end
