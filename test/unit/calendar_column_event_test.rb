#
# $Id: calendar_column_event_test.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarEventColumnTest < ActiveSupport::TestCase

  include Calendar::Event::InstanceMethods

  class TestEvent 
    include Calendar::Event::BaseMethods
    include Calendar::Display::Render
    has_renderer

    def initialize(s, e)
      initialize_base(s, e)
    end

    def render
      return TestEventRenderer.new(self)
    end
  end

  def setup
    assert @start_date = Time.zone.local(2009, 12, 14).monday + 8.hours
    assert @end_date = @start_date + 1.hour
    assert_equal 1, @start_date.wday
    assert_equal 1, @end_date.wday
    assert @c = Calendar::Event::Column.new
  end

  test "regular addition" do
    regular_events =
    [ 
      TestEvent.new(@start_date, @end_date),
      TestEvent.new(@start_date + 1.hour, @end_date + 1.hour),
      TestEvent.new(@start_date + 2.hour, @end_date + 2.hour),
    ]
    ed = nil
    regular_events.each do
      |e|
      assert @c << e
      assert_equal @start_date, @c.start_date
      assert_equal e.end_date, @c.end_date
    end
  end

  test "overlapping exceptions" do
    ole =
    [ 
      TestEvent.new(@start_date, @end_date),
      TestEvent.new(@start_date + 30.minutes, @end_date + 1.hour),
    ]
    assert @c << ole[0]
    assert_raise(Calendar::Event::Column::OverlappingEvent) { assert @c << ole[1] }
  end

  test "out of time ordering exceptions" do
    ole =
    [ 
      TestEvent.new(@start_date, @end_date),
      TestEvent.new(@start_date - 30.minutes, @end_date + 1.hour),
    ]
    assert @c << ole[0]
    assert_raise(Calendar::Event::Column::NonTimeOrderedEvent) { assert @c << ole[1] }
  end

  test "rendering with regular additions" do
    regular_events =
    [ 
      TestEvent.new(@start_date, @end_date),
      TestEvent.new(@start_date + 3.hour, @end_date + 4.hour),
      TestEvent.new(@start_date + 6.hour, @end_date + 7.hour),
    ]
    ed = nil
    regular_events.each do
      |e|
      assert @c << e
      assert_equal @start_date, @c.start_date
      assert_equal e.end_date, @c.end_date
    end

  end

end
