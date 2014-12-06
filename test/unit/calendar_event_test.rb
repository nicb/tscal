#
# $Id: calendar_event_test.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarEventTest < ActiveSupport::TestCase

  class TestEvent 
    include Calendar::Event::BaseMethods

    def initialize(sd, ed)
      initialize_base(sd, ed)
    end
  end

  include Calendar::Display::Week::Methods

  def setup
    now = Time.zone.now
    @start_date = Time.zone.local(now.year, now.month, now.day, 12, 00)
    @end_date = @start_date + 45.minutes
  end

  test "base event creation" do
    assert e = TestEvent.new(@start_date, @end_date)
    assert_equal @start_date, e.start_date
    assert_equal @end_date, e.end_date
  end

  test "base event duration" do
    assert e = TestEvent.new(@start_date, @end_date)
    assert_equal (@end_date - @start_date) / 60.0, e.duration
  end

  test "base event boundary changes" do
    changes = [-15, 30, 3600]
    #
    # start_date changes
    #
    execute_changes(changes) do
      |e, dur, secs|
      sd = e.start_date + secs
      ed = e.end_date
      assert e.start_date = sd
      assert_equal dur, e.duration
      assert_equal sd, e.start_date
      assert_equal ed + secs, e.end_date
    end
    #
    # end_date changes
    #
    execute_changes(changes) do
      |e, dur, secs|
      ed = @end_date + secs
      sd = e.start_date
      assert e.end_date = ed
      assert_equal dur.minutes + secs, e.duration.minutes
      assert_equal ed, e.end_date
      assert_equal sd, e.start_date
    end
  end

private

  def execute_changes(c_array)
    c_array.each do
      |add|
      assert ev = TestEvent.new(@start_date, @end_date)
      assert dur = ev.duration
      assert_equal add * 60, secs = add.minutes
      yield(ev, dur, secs)
    end
  end

end
