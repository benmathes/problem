

# A transaction.
# belongs to a recurrence and timeline
class Transaction
  attr_accessor :timeline, :recurrence, :amount, :date, :sources, :allocations, :spendable
  def initialize(timeline:, recurrence:, amount:, date:)
    @timeline = timeline
    @amount = amount
    @recurrence = recurrence
    @date = date
    @sources = []
    @allocations = []
    @spendable = nil
  end

  def unallocated
    allocated = @allocations.map{|allocation| allocation[:amount]}.reduce(:+) || 0
    @amount - allocated
  end

  def sourced?
    sourced = @sources.map{|source| source[:amount]}.reduce(:+) || 0
    sourced >= @amount
  end

  def income?
    return recurrence.kind_of? Income
  end

  def expense?
    return recurrence.kind_of? Expense
  end

#  def to_s
#    "<txn: #{date} for #{self.amount}>"
#  end
#
#  def inspect
#    "<txn: #{date} for #{self.amount}, recurrence: #{@recurrence.to_s}, allocations: #{@allocations.inspect}, sources: #{@sources.inspect} spendable: #{@spendable}>"
#  end

end
