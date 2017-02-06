require "minitest/autorun"
require 'pp'
require 'json'
require 'pry'
require 'active_support'
require 'active_support/core_ext/numeric/time'
require 'date'

require './transaction'
require './timeline'
require './recurrence'
require './schedule'

VERBOSE = false

describe Timeline do
  before do
    @json_incomes = [
      {
        "name" => "Walmart",
        "amount" => 300,
        "type" => "PRIMARY",
        "schedule" => {
          "type" => "MONTHLY",
          "days" => [1, 15]
        }
      },
    ]
    @json_expenses = [
      {
        "name" => "Rent",
        "amount" => 120,
        "schedule" => {
          "type" => "MONTHLY",
          "days" => 1,
          "start" => "2016-01-01"
        }
      },
      {
        "name" => "groceries",
        "amount" => 50,
        "schedule" => {
          "type" => "INTERVAL",
          "period" => 7,
          "start" => "2016-01-01"
        }
      },
    ]
    @timeline = Timeline.new(
      incomes: @json_incomes,
      expenses: @json_expenses,
      start_date: Date.parse('2016-1-1'),
      end_date: Date.parse('2016-2-1')
    )
    @timeline.plan!
  end

  describe "timeline generation" do
    it "should have correct # of transactions" do
      assert_equal 8, @timeline.flattened.length
    end
  end

  describe "solvency" do
    it "should detect solvency" do
      assert @timeline.solvent?
    end

    it "should detect insolvency" do
      luxury_groceries = @json_expenses
      luxury_groceries[1]["amount"] = 300
      insolvent_timeline = Timeline.new(
        incomes: @json_incomes,
        expenses: luxury_groceries,
        start_date: Date.parse('2016-1-1'),
        end_date: Date.parse('2016-2-1')
      )
      refute insolvent_timeline.solvent?
    end
  end

  describe "allocations" do
    it "all expenses sourced" do
      @timeline.flattened.select(&:expense?).each do |expense|
        assert_equal expense.sourced, expense.amount.abs
      end
    end

    it "no income over-allocated" do
      @timeline.flattened.select(&:income?).each do |income|
        assert(
          income.allocated < income.amount.abs,
          "cannot allocate more than income amount"
        )
      end
    end
  end

  describe "smoothing" do
    it "daily smoothed spending should be non-decreasing" do
      previous_daily_spend = 0
      @timeline.days.each do |day|
        next if day.nil?
        assert previous_daily_spend <= day.smoothed_daily_spendable
        previous_daily_spend = day.smoothed_daily_spendable
      end
    end

	# todo: decreasing unsmoothed daily spend

	# todo: increasing unsmoothed daily spend

	# todo: cascading-down sets of decreasing unsmoothed daily spend
  end

end
