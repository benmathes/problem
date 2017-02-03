require 'pp'
require 'json'
require 'pry'
require 'active_support'
require 'active_support/core_ext/numeric/time'

puts "reading file..."
fileText = STDIN.read

puts "parsing file..."
input = JSON.parse(fileText)

START_DATE = Date.parse('2016-01-01')
END_DATE = Date.parse('2017-01-01')


# Assumptions about ambiguities baked in as feature toggles:

# Does an interval bill/income start on its start date?
INTERVALS_START_ON_DAY_1 = true


# A Timeline
# has many incomes, expenses
# stores an internal timeline, generated from the periodic incomes/expenses
# answers questions like: is is solvent? What's the daily allowable spending money?
class Timeline
  attr_accessor :incomes, :expenses, :timeline, :start, :end

  def initialize(incomes:, expenses:)
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

  def solvent?

  end
end


# A recurrence.
# has one Schedule
# has many Transactions
# belongs to a Timeline
class Recurrence
  attr_accessor :name, :type, :amount, :schedule
  def initialize(timeline:, name:, type:, amount:, schedule:)
    @timeline = timeline
    @name = name
    @type = type
    @amount = amount
    @schedule = Schedule.new(
      recurrence: self,
      type: schedule["type"],
      period: schedule["period"],
      start: schedule["start"] || timeline.start,
      days: schedule["days"]
    )
  end

  # generates all the transactions for a recurrence.
  # only does this once, then returns the cached transactions
  # if already done
  def transactions(timeline_start:, timeline_end:)
    return @transactions if !@transactions.nil?
    @transactions = []
    if @schedule.type == 'ONE_TIME'
      puts "  one time.:"
      puts "    transaction on #{@schedule.start} for #{@amount}"
      @transactions.push Transaction.new(
        timeline: @timeline,
        recurrence: self,
        amount: @amount,
        date: @schedule.start)
    elsif @schedule.type == 'MONTHLY'
      puts "  monthly.: "
      # round down day of month in case timeline start is not at day 1 of months)
      current = @schedule.start.change(day: 1)
      while current < timeline_end
        @schedule.days.each do |day_of_month|
          puts "    transaction on #{current + day_of_month - 1} for #{@amount}"
          @transactions.push Transaction.new(
            timeline: @timeline,
            recurrence: self,
            amount: @amount,
            date: (current + day_of_month - 1))
        end
        current = current.to_time.advance(:months => 1).to_date.change(day: 1)
      end
    elsif @schedule.type == 'INTERVAL'
      puts "  interval.:"
      current = @schedule.start
      current = current + @schedule.period unless INTERVALS_START_ON_DAY_1
      while current <= timeline_end
        puts "    transaction on #{current} for #{@amount}"
        transaction = Transaction.new(
          timeline: @timeline,
          recurrence: self,
          amount: @amount,
          date: current)
        @transactions.push transaction
        current += @schedule.period
      end
    end
    return @transactions
  end
end


# TODO: necessary?
class Income < Recurrence
end
class Expense < Recurrence
  def amount
    return -1 * @amount
  end
end



# A recurrence schedule.
# belongs to a recurrence
class Schedule
  attr_accessor :recurrence, :type, :period, :start, :days
  def initialize(recurrence:, type:, period:, start:, days:)
    @type = type
    @period = period
    @start = start.kind_of?(Date) ? start : Date.parse(start)
    @days = days
  end
end


# A transaction.
# belongs to a recurrence and timeline
class Transaction
  attr_accessor :timeline, :recurrence, :amount, :date
  def initialize(timeline:, recurrence:, amount:, date:)
    @timeline = timeline
    @amout = amount
    @recurrence = recurrence
    @date = date
  end
end


timeline = Timeline.new(
  incomes: input["incomes"],
  expenses: input["expenses"]
)

puts "done"
