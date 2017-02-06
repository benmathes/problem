class Day
  # a day of transactions
  attr_accessor :timeline, :txns, :unsmoothed_daily_spendable, :smoothed_daily_spendable,
                :next_income_day, :next_expense_day, :date, :timeline_index, :unsmoothed_spendable

  def initialize(timeline:, timeline_index:, date:, txns: [])
    @timeline = timeline
    @timeline_index = timeline_index
    @date = date
    @_txns = txns
    @unsmoothed_daily_spendable = nil
    @smoothed_daily_spendable = nil
    @unsmoothed_spendable = nil
    @next_income_day = nil
    @next_expense_day = nil
    @_looked_for_next_income = false
  end


  def txns
    # As per problem definition, incomes go before expenses on a day
    incomes.concat expenses
  end

  def add_txn(txn)
    @_txns.push txn
  end


  # warning: implicit cache. if a day's daily spendable changes,
  # the day's value will be out of date.
  def unsmoothed_daily_spendable
    if @unsmoothed_daily_spendable.nil?
      @unsmoothed_daily_spendable = incomes.map(&:unsmoothed_daily_spendable).compact.reduce(&:+)
    else
      @unsmoothed_daily_spendable
    end
  end


  # warning: implicit cache. if a day's daily spendable changes,
  # the day's value will be out of date.
  def smoothed_daily_spendable
    if @smoothed_daily_spendable.nil?
      @smoothed_daily_spendable = incomes.map(&:smoothed_daily_spendable).compact.reduce(&:+)
    else
      @smoothed_daily_spendable
    end
  end


  def next_income_day
    return @next_income_day if @_looked_for_next_income
    @_looked_for_next_income = true

    @timeline.days[@timeline_index+1..-1].each_with_index do |future_day, i|
      if !future_day.nil? && future_day.incomes.length > 0
        @next_income_day = future_day
        return future_day
      end
    end
    @next_income_day = nil
  end


  def days_til_next_income
    if next_income_day.nil?
      timeline.end_date - date
    else
      next_income_day.date - date
    end
  end


  def allocate_daily_spendable(amount)
    # given a daily spendable amount, spread it around the incomes on that day
    incomes.each do |income|
      amount = income.allocate(amount)
    end
  end


  def incomes
    @_txns.select(&:income?)
  end


  def expenses
    @_txns.select(&:expense?)
  end


  def inspect
    to_s
  end


  def to_s
    "<Day date: #{date}, next_income_date: #{next_income_day.try(:date)}, smoothed daily:#{smoothed_daily_spendable}, #incomes: #{incomes.length}, #expenses: #{expenses.length}>"
  end

end
