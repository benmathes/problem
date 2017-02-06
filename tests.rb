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

    def assert_smoothed(timeline = nil)
      timeline ||= @timeline
      previous_daily_spend = timeline.income_days[0].smoothed_daily_spendable
      timeline.income_days.each do |day|
        assert previous_daily_spend <= day.smoothed_daily_spendable + Timeline::SMOOTHING_FUZZINESS
        previous_daily_spend = day.smoothed_daily_spendable
      end
    end

    it "daily smoothed spending should be present for all days with income" do
      @timeline.income_days.each do |day|
        assert !day.smoothed_daily_spendable.nil?
      end
    end

    it "daily smoothed spending should be non-decreasing" do
      assert_smoothed
    end

    it "should work with decreasing unsmoothed daily spend" do
      json_incomes = [
        {
          "name" => "Walmart", "amount" => 10, "schedule" => {
            "type" => "MONTHLY",
            "days" => [1, 5, 10]
          }
        },
      ]
      json_expenses = [
        {
          "name" => "cost1", "amount" => 1, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-01-03"
          }
        },
        {
          "name" => "cost2", "amount" => 3, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-01-07"
          }
        },
        {
          "name" => "cost3", "amount" => 5, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-01-17"
          }
        },
      ]
      timeline = Timeline.new(
        incomes: json_incomes,
        expenses: json_expenses,
        start_date: Date.parse('2016-1-1'),
        end_date: Date.parse('2016-2-1')
      )
      timeline.plan!
      assert timeline.solvent?
      assert_smoothed(timeline)
    end

    it "should work with increasing unsmoothed daily spend" do
      json_incomes = [
        {
          "name" => "Walmart", "amount" => 10, "schedule" => {
            "type" => "MONTHLY",
            "days" => [1, 5, 10]
          }
        },
      ]
      json_expenses = [
        {
          "name" => "cost1", "amount" => 5, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-01-03"
          }
        },
        {
          "name" => "cost2", "amount" => 3, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-01-07"
          }
        },
        {
          "name" => "cost3", "amount" => 1, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-01-17"
          }
        },
      ]
      timeline = Timeline.new(
        incomes: json_incomes,
        expenses: json_expenses,
        start_date: Date.parse('2016-1-1'),
        end_date: Date.parse('2016-2-1')
      )
      timeline.plan!
      assert timeline.solvent?
      assert_smoothed(timeline)
    end

    it "cascading-down sets of decreasing unsmoothed daily spend" do
      json_incomes = [
        {
          "name" => "Walmart", "amount" => 200, "schedule" => {
            "type" => "MONTHLY",
            "days" => 1
          }
        },
      ]
      json_expenses = [
        {
          "name" => "cost1", "amount" => 10, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-01-03"
          }
        },
        {
          "name" => "cost2", "amount" => 30, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-01-07"
          }
        },
        {
          "name" => "cost3", "amount" => 50, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-01-17"
          }
        },
        {
          "name" => "cost4", "amount" => 20, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-02-03"
          }
        },
        {
          "name" => "cost5", "amount" => 40, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-02-07"
          }
        },
        {
          "name" => "cost6", "amount" => 60, "schedule" => {
            "type" => "ONE_TIME",
            "start" => "2016-03-17"
          }
        },
      ]
      timeline = Timeline.new(
        incomes: json_incomes,
        expenses: json_expenses,
        start_date: Date.parse('2016-1-1'),
        end_date: Date.parse('2016-3-1')
      )
      timeline.plan!
      assert timeline.solvent?
      assert_smoothed(timeline)
    end
  end

end
