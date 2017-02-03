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

VERBOSE = false

require './timeline'
require './recurrence'
require './schedule'
require './transaction'


timeline = Timeline.new(
  incomes: input["incomes"],
  expenses: input["expenses"]
)

unless timeline.solvent?
  result = { error: "Insolvent" }
else
  result = timeline.plan
end

puts result
