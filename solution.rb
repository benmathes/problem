require 'pp'
require 'json'
require 'pry'

puts "reading file..."
fileText = STDIN.read

puts "parsing file..."
input = JSON.parse(fileText)

START_DATE = Date.parse('2016-01-01')
END_DATE = Date.parse('2017-01-01')


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
    pp @incomes
    @timeline ||= []
    @incomes.each do |income|
      pp income.schedule
    end
  end

  def solvent?

  end
end


# A recurrence.
# has one schedule
# belongs to a timeline
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
      start: schedule["start"] || timeline.start
    )
  end

  def instances
    if @instances.nil?
      @instances = []
    else
      return @instances
    end
  end
end


# TODO: necessary?
class Income < Recurrence
end
class Expense < Recurrence
end



# A recurrence schedule.
# belongs to a recurrence
class Schedule
  attr_accessor :recurrence, :type, :period, :start
  def initialize(recurrence:, type:, period:, start:)
    @type = type
    @period = period
    @start = start.kind_of?(Date) ? start : DateTime.parse(start)
  end
end


# A transaction.
# belongs to a recurrence and timeline
class Transaction
  attr_accessor :timeline, :recurrence, :amount
  def initialize(timeline:, recurrence:, amount:)
    @amout = amount
    @recurrence = recurrence
  end
end




timeline = Timeline.new(
  incomes: input["incomes"],
  expenses: input["expenses"]
)


pp timeline
