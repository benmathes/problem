class Transaction
  # A transaction.
  # belongs to a recurrence and timeline
  # TODO: either transactions be subclassed into Transaction::Income and
  # Transaction::Expense, or Recurrence::Income and Recurrence::Expense shouldn't exist
  # either consistently live in the higher level of abstraction: recurrence-<transaction
  # or in lower level of income/expense sources -< income/expense transactions
  # This comes up is, e.g. Transaction#sourced? and Transaction#allocated?, where
  # I have re-implemented partial type checking.

  attr_accessor :timeline, :recurrence, :amount, :date, :sources, :allocations, :spendable,
                :unsmoothed_daily_spendable, :smoothed_daily_spendable, :next_income
  def initialize(timeline:, recurrence:, amount:, date:)
    @timeline = timeline
    @amount = amount
    @recurrence = recurrence
    @date = date
    @sources = []
    @allocations = []
    @spendable = nil
    @smoothed_daily_spendable = nil
    @unsmoothed_daily_spendable = nil
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
    next_income.date - @date
  end


  def next_income
    if @next_income.nil?
      @next_income = timeline.next_income_day(timeline_index)
    end
    @next_income
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
      hash[:smoothed_daily_spendable] = @smoothed_daily_spendable
      hash[:unsmoothed_daily_spendable] = @unsmoothed_daily_spendable
      hash[:allocations] = @allocations
    elsif expense?
      hash[:sources] = @sources
    end
    hash
  end
end
