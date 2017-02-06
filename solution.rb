require 'pp'
require 'json'
require 'pry'
require 'slop'
require 'active_support'
require 'active_support/core_ext/numeric/time'

opts = Slop.parse do
  on 'v', 'verbose', 'enable verbose mode'
  on 'd', 'daily', 'daily output instead of transaction output'
end

START_DATE = Date.parse('2016-01-01')
END_DATE = Date.parse('2017-01-01')
VERBOSE = opts.verbose? || false

puts "reading file..." if VERBOSE
fileText =  STDIN.read

puts "parsing file..." if VERBOSE
input = JSON.parse(fileText)

# local project files
require './timeline'
require './recurrence'
require './schedule'
require './transaction'
require './day'

timeline = Timeline.new(
  incomes: input["incomes"],
  expenses: input["expenses"],
  start_date: START_DATE,
  end_date: END_DATE,
)

unless timeline.solvent?
  result = { error: "Insolvent" }
else
  timeline.plan!
  if opts.daily?
    result = { days: timeline.days.compact.map{ |day| day.to_hash } }
  else
    result = { events: timeline.flattened.map{|event| event.to_hash } }
  end
end

timeline.chart!

puts result.to_json
