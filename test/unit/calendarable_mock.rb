#
# $Id: calendarable_mock.rb 192 2009-12-14 22:49:48Z nicb $
#
# This is a mock calendarable class to be used when testing
# (to make sure that the Calendarable module works by itself)
#
# A test must include some setup and teardown like this:
#
# require 'calendarable_mock'
#
# def setup
#   ActiveRecord::Migration.verbose = false
#   CreateCalendarableMock.up
# end
#
# def teardown
#   ActiveRecord::Migration.verbose = false
#   CreateCalendarableMock.down
# end
#

class CreateCalendarableMock < ActiveRecord::Migration
  def self.up
    create_table :calendarable_mocks do |t|
      t.datetime :start_date, :null => false
      t.datetime :end_date, :null => false
      t.string   :filter
    end
  end
  def self.down
    drop_table :calendarable_mocks
  end
end

class CalendarableMock < ActiveRecord::Base
  include Calendarable

  validates_presence_of :start_date, :end_date

  def raw_start_date=(d)
    return write_attribute(:start_date, d)
  end

  def start_date
    return read_attribute(:start_date)
  end
  def end_date
    return read_attribute(:end_date)
  end
  def topic_display
    return start_date.to_s + '-' + end_date.to_s
  end

  alias :topic_display_tooltip  :topic_display 
  alias :course_display         :topic_display 
  alias :course_display_tooltip :course_display

  def initialize(parms = {})
    super(handle_duration_arg(parms))
  end
  
  class <<self

    def filtered(ts, te, filter=nil)
      condition_string = "(start_date >= ? and end_date <= ?)"
      conds = [ ts, te ]
      if filter
        condition_string += " and (filter = ?)"
        conds = filter
      end
      conds.unshift(condition_string)
      return all(:conditions => conds)
    end

    def manage_filter(filter)
      return filter
    end

  end

end
