require 'pp'
require 'json'
require 'pry'
require 'active_support'
require 'active_support/core_ext/numeric/time'

START_DATE = Date.parse('2016-01-01')
END_DATE = Date.parse('2017-01-01')
VERBOSE = false

puts "reading file..." if VERBOSE
fileText =  STDIN.read

puts "parsing file..." if VERBOSE
input = JSON.parse(fileText)

# local project files
require './timeline'
require './recurrence'
require './schedule'
require './transaction'

timeline = Timeline.new(
  incomes: input["incomes"],
  expenses: input["expenses"],
  start_date: START_DATE,
  end_date: END_DATE,
)

unless timeline.solvent?
  result = { error: "Insolvent" }
else
  result = { events: timeline.plan!.map{|event| event.to_hash } }
end

timeline.chart!

puts result.to_json
