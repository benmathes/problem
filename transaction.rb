# A transaction.
# belongs to a recurrence and timeline
class Transaction
  attr_accessor :timeline, :recurrence, :amount, :date, :sources, :allocations, :spendable,
                :unsmoothed_daily_spend, :daily_spend, :next_income
  def initialize(timeline:, recurrence:, amount:, date:)
    @timeline = timeline
    @amount = amount
    @recurrence = recurrence
    @date = date
    @sources = []
    @allocations = []
    @daily_spend = nil
    @spendable = nil
    @unsmoothed_daily_spend = nil
  end

  def spendable
    @spendable.nil? ? @amount : @spendable
  end

  def unallocated
    @amount.abs - allocated
  end

  def allocated
    @allocations.map{|allocation| allocation[:amount].abs}.reduce(:+) || 0
  end

  def sourced
    @sources.map{|source| source[:amount].abs}.reduce(:+) || 0
  end

  def unsourced
    @amount.abs - sourced
  end

  def sourced?
    throw Error("incomes aren't sourced") if income?
    sourced = @sources.map{|source| source[:amount].abs}.reduce(:+) || 0
    sourced >= @amount.abs
  end

  def allocated?
    throw Error("expenses aren't allocated") if expense?
    sourced = @allocations.map{|allocation| allocation[:amount].abs}.reduce(:+) || 0
    sourced >= @amount.abs
  end

  def income?
    return recurrence.kind_of? Income
  end

  def expense?
    return recurrence.kind_of? Expense
  end

  def days_til_next_income
    @next_income.date - @date
  end

  def to_hash
    hash = {
      type: income? ? "income" : "expense",
      name: @recurrence.name,
      date: @date,
      amount: @amount
    }
    if income?
      hash[:spendable] = spendable
      hash[:daily_spend] = @daily_spend
      hash[:unsmoothed_daily_spend] = @unsmoothed_daily_spend
      hash[:allocations] = @allocations
    elsif expense?
      hash[:sources] = @sources
    end
    hash
  end
end
