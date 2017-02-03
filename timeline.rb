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
  end

  def generate
    # @timeline is an array indexed on day of the year
    # where we will mark all the incomes/expenses.
    # e.g. @timeline[0] = [<Transaction>, <Transaction>]
    # TODO: make this a sparse-er data store.
    return @timeline unless @timeline.nil?
    @timeline = []

    # TODO: we put income before expenses on each day on purpose. That's part of the assumption.
    # a less brittle approach would be to enforce the order in some kind of date.get_transaction()
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

  def plan
    # Go backwards to find money to cover expenses. There could be a more mathematically clean
    # way to do this. but the algorithm should be:
    # 1) simple: easy to prove it will never ruin the customer
    # 2) simple: easy to trust by the end user!
    reversed = flattened.reverse
    reversed.each_with_index do |txn, i|
      # if it's an expense...
      if txn.expense?
        # go back in time to find the covering income
        reversed[i..-1].each_with_index do |prior_txn|
          break if txn.sourced?
          if prior_txn.income?
            # ensure we haven't already allocated funds for this prior income
            next if prior_txn.unallocated <= 0

            if txn.amount <= prior_txn.unallocated
              allocation_amount = txn.amount
            else
              allocation_amount = prior_txn.unallocated
            end

            prior_txn.allocations.push({
              name: txn.recurrence.name,
              date: txn.date,
              amount: allocation_amount.abs
            })

            # after allocationg the prior txn, bring down spendable
            prior_txn.spendable = (prior_txn.spendable || prior_txn.amount) - allocation_amount

            # if we are solvent this shouldn't happen -- sanity check
            if prior_txn.spendable < 0
              throw Error("Should never allocate more than ")
            end

            txn.sources.push({
              name: prior_txn.recurrence.name,
              date: prior_txn.date,
              amount: allocation_amount.abs
            })
          end
        end
      end
      #pp txn
      exit
    end

    # straighten it out again
    return reversed.reverse
  end

end
