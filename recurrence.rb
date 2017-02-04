
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
      start: schedule["start"] || timeline.start_date,
      days: schedule["days"]
    )
  end

  # generates all the transactions for a recurrence.
  # only does this once, then returns the cached transactions
  # if already done
  def transactions(timeline_start:, timeline_end:)
    @transactions = []
    if @schedule.type == 'ONE_TIME'
      t = Transaction.new(
        timeline: @timeline,
        recurrence: self,
        amount: self.amount,
        date: @schedule.start)
      @transactions.push t
    elsif @schedule.type == 'MONTHLY'
      # TODO: start at start date, monthly dates afterwards
      current = @schedule.start
      while current < timeline_end
        start_of_month = current.change(day: 1)
        days = @schedule.days.respond_to?(:each) ? @schedule.days : [@schedule.days]
        days.each do |day_of_month|
          # edge case: start date of monthly > 1st day of month.
          # e.g. days [1,15], but start date 2016-2-3
          this_transaction_date = start_of_month + day_of_month - 1
          next if this_transaction_date < @schedule.start
          t = Transaction.new(
            timeline: @timeline,
            recurrence: self,
            amount: self.amount,
            date: this_transaction_date)
          @transactions.push t
        end
        current = current.to_time.advance(:months => 1).to_date.change(day: 1)
      end
    elsif @schedule.type == 'INTERVAL'
      current = @schedule.start
      while current <= timeline_end
        t = Transaction.new(
          timeline: @timeline,
          recurrence: self,
          amount: self.amount,
          date: current)
        @transactions.push t
        current += @schedule.period
      end
    end
    return @transactions
  end

  def to_s
    return "<#{self.class}: name: #{self.name} amount: #{self.amount} type: #{@schedule.type}>"
  end

  def inspect
    return "<#{self.class}: name: #{self.name} amount: #{self.amount} type: #{@schedule.type}>"
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
