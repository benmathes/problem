require 'gruff'
require './day'

class Timeline
  # A Timeline
  # has many incomes, expenses
  # stores an internal timeline, generated from the periodic incomes/expenses
  # answers questions like: is is solvent? What's the daily allowable spending money?

  attr_accessor :incomes, :expenses, :timeline, :start_date, :end_date, :stats, :days

  def initialize(incomes:, expenses:, start_date:, end_date:)
    @stats = {
      income: { total: nil, avg: nil },
      expenses: { total: nil, avg: nil }
    }
    @solvent = nil
    @start_date = start_date
    @end_date = end_date
    @days = nil
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


  def generate(force: false)
    # @days is an array indexed on day of the year
    # where we will mark all the incomes/expenses.
    # TODO: make this a sparse-er data store, e.g. a linked list or sparse array
    return @days if !@days.nil? && !force
    @days = []
    @incomes.concat(@expenses).each do |recurrence|
      txns = recurrence.transactions(timeline_start: self.start_date, timeline_end: self.end_date)
      txns.each do |txn|
        if @days[txn.date.yday].nil?
          @days[txn.date.yday] = Day.new(
            timeline: self,
            timeline_index: txn.date.yday,
            date: txn.date
          )
        end
        @days[txn.date.yday].add_txn txn
      end
    end
    return @days
  end


  # returns the flattened list of transactions for the year,
  # removing nil days (i.e. no transactions)
  # e.g. [[income, expense], nil, [income]] -> [income, expense, income]
  def flattened(force: true)
    return @flattened unless @flattened.nil?
    @flattened = []
    @days.each do |day|
      next if day.nil?
      day.txns.each do |transaction|
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
    @stats[:income][:avg] = total_income/(@end_date - @start_date - 1)
    @stats[:expenses][:total] = total_expenses
    @stats[:expenses][:avg] = total_expenses/(@end_date - @start_date - 1)
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

  def income_days
    days.reject{|d| d.nil? || d.incomes.length == 0}
  end

  def plan!
    allocate!
    plan_daily_spend!
    return @planned
  end


  def chart!
    g = Gruff::Line.new
    g.title = 'spendable over time'

    series = {}
    [:unsmoothed_daily_spendable, :smoothed_daily_spendable].each do |attr|
      prior = 0
      series[attr] = []
      days.each do |day|
        next if day.nil? || day.incomes.length == 0
        series[attr].push [day.date.to_time.to_i, prior]
        series[attr].push [day.date.to_time.to_i, day.try(attr)]
        prior = day.try(attr)
      end
      g.dataxy attr, series[attr]
    end
    g.write 'charts.png'
  end


  def next_income_day(day_index)
    @days[day_index].next_income_day
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

      # go back in time to find the closest covering incomes
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
        income.spendable = income.spendable - allocation_amount

        # if we are solvent this shouldn't happen -- sanity check
        if income.spendable < 0
          throw Error("Should never allocate more than amount of income transaction.")
        end
      end
    end
    return flattened
  end


  def plan_daily_spend!
    # ASSUMPTION: Timeline#allocate! already run. this method private to ensure
    # go forward through time, checking how much
    # of a paycheck is unallocated (Transaction#spendable),
    # and spread it forward until next income. If next income
    # is less, spreads all past income forward so daily spend
    # is non-decreasing over entire timeline.

    # first pass, calc daily spend between days with income, no smoothing.
    @days.each_with_index do |day, i|
      next if day.nil? || day.incomes.length == 0
      # default days_between is 1 in case income on last day,
      # denominator in avg spend per day. (prevent divide-by-zero). or:
      # the identity unit in integers under mult/division is 1, not 0 like
      # addition (groups/rings/fields)
      next_day = next_income_day(i)
      days_between =  next_day.nil? ? 1 : next_day.date - day.date
      day.incomes.each do |income|
        income.unsmoothed_daily_spendable = income.spendable / days_between
      end
    end

    # TODO: smooth in the same loop as calc'ing spend/day?
    infinite_guard = 0
    loop do
      still_smoothing = false
      # managing loop variables outside since ruby does not persist changes to
      # iteration variables in multiple runs of the loop.
      i_smooth_window_start = 0
      puts "new full smooth pass:" if VERBOSE
      while i_smooth_window_start < @days.length
        window_start_day = @days[i_smooth_window_start]
        next if window_start_day.nil? || window_start_day.incomes.length == 0
        # inner loop that goes forward through time until we hit a daily spend that goes up
        # (i.e. no need to push forward income up to this point). Smooth up to end of inner day, e.g.
        #   __
        # _|  |__      ______
        #        |____|
        #---------------------
        #  ^__________^
        #    1 window
        if window_start_day.next_income_day.nil?
          # if done with inner loop and ended at end of timeline,
          # break to outer global smoothing loop
          break
        end

        puts "  new local smooth: start #{window_start_day.date}" if VERBOSE
        i_inner_day = i_smooth_window_start
        while i_inner_day < @days.length
          inner_day = @days[i_inner_day]
          next if inner_day.nil? || inner_day.incomes.length == 0

          puts "    local smooth: start #{window_start_day.date}, inner: #{inner_day.date}" if VERBOSE
          # since multiple outer smoothing passes, default to prior smoothing, but
          # if that doesn't exist, use unsmoothed.
          current_smoothed_daily_spendable = (window_start_day.smoothed_daily_spendable || window_start_day.unsmoothed_daily_spendable)
          next_smoothed_daily_spendable = (inner_day.smoothed_daily_spendable || inner_day.unsmoothed_daily_spendable)

          if current_smoothed_daily_spendable > next_smoothed_daily_spendable
            still_smoothing = true
            # next is lower: push income forward, i.e. local smoothing
            days_up_to_now = inner_day.date - window_start_day.date
            total_smooth_spend_to_now = current_smoothed_daily_spendable * days_up_to_now
            total_smooth_spend_next = next_smoothed_daily_spendable * inner_day.days_til_next_income
            num_smooth_days = days_up_to_now + inner_day.days_til_next_income
            new_smoothed_daily_spendable = (total_smooth_spend_to_now + total_smooth_spend_next) / num_smooth_days
            # have to loop through whole window to update (TODO: do I?). sloow. O(n^2)
            back_propagate_day = window_start_day
            while back_propagate_day.date != inner_day.date
              back_propagate_day.smoothed_daily_spendable = new_smoothed_daily_spendable
              back_propagate_day = back_propagate_day.next_income_day
            end
            # inner loop iteration step.
            if inner_day.next_income_day.nil?
              # end of timeline, back to start for another global smooth pass
              i_inner_day = @days.length
              i_smooth_window_start = @days.length
            else
              i_inner_day = inner_day.next_income_day.timeline_index
            end
            puts "      down: #{current_smoothed_daily_spendable}/day, #{days_up_to_now}d -> #{next_smoothed_daily_spendable}/day, #{inner_day.days_til_next_income}d, new: #{new_smoothed_daily_spendable}/day for #{num_smooth_days}d" if VERBOSE
          elsif current_smoothed_daily_spendable <= next_smoothed_daily_spendable
            # next is higher: done smoothing to here. pull outer window forward
            puts "      up: #{current_smoothed_daily_spendable} < #{next_smoothed_daily_spendable}/day. moving smooth_window_start to #{inner_day.date}" if VERBOSE
            i_smooth_window_start = inner_day.timeline_index
            current_smoothed_daily_spendable = next_smoothed_daily_spendable
            break
          end
        end
      end
      # TODO: a little hack-y to prevent infinite looping like this.
      infinite_guard += 1
      raise "infinite loop" if infinite_guard > 9999

      i_smooth_window_start += 1
      break unless !still_smoothing
    end

    # TODO: calculated spend for days, spread to incomes on those days
  end
end


class Float
  def to_s
    return self.round(2).inspect
  end
end
