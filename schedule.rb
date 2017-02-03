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
