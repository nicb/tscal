#
# $Id: calendar_week_day_column_test.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarDayColumnTest < ActiveSupport::TestCase

  class TestEvent
    include Calendar::Event::BaseMethods
    include Calendar::Display::Render
    has_renderer

    def initialize(ds, de)
      initialize_base(ds, de)
    end

    def renderer
      return TestEventRenderer.new(self)
    end
  end

  include Calendar::Display::Week::Methods

  def setup
    assert @day = Time.zone.local(2009, 12, 14)
    assert @start_date = @day + DAY_HOUR_START.hour
    assert @end_date = @day + DAY_HOUR_END.hour
    assert_equal 1, @start_date.wday
    assert_equal 1, @end_date.wday
    assert @c = Calendar::Display::Week::Day.new(@day)
  end

  test "day start and day end" do
    assert_equal @start_date, @c.day_start
    assert_equal @end_date, @c.day_end
  end

  test "day with disjointed events" do
    curt = @start_date + 1.hour
    while (curt < @end_date)
      @c << TestEvent.new(curt, curt + 1.hour)
      curt += 2.hours
    end
    @c.each do
      |e|
      height_should_be = ((e.duration.to_f / cell_time.to_f) * row_height.to_f).round - 2 # 2 px for top-bottom borders
      assert_equal TestEvent, e.class
      assert_equal height_should_be, e.height
    end
  end

  test "day with adjacent events" do
    curt = @start_date
    while (curt < @end_date)
      @c << TestEvent.new(curt, curt + 1.hour)
      curt += 1.hour
    end
    @c.each do
      |e|
      should_be = TestEvent
      height_should_be = ((e.duration.to_f / cell_time.to_f) * row_height.to_f).round - 2 # 2 px for top-bottom borders
      assert_equal should_be, e.class
      assert_equal height_should_be, e.height
    end
  end

  test "render with no events" do
    #
    # if we render without event a single Event::Empty should occupy the whole
    # day
    #
    assert r = @c.renderer
    assert_equal 'calendar/week/day', r.template
    assert_equal Calendar::Display::Week::Day::DayRenderer, r.class
    assert_equal 1, r.object[:events].size
    assert_equal Calendar::Event::Empty::EmptyRenderer, r.object[:events][0].class
    height_should_be = ((((@c.day_end - @c.day_start).seconds/60.0) / cell_time.to_f) * row_height.to_f).round
    assert_equal height_should_be, r.object[:events][0].object.height
  end

  test "render trailing empty space" do
    assert @c << TestEvent.new(@start_date, @start_date.since(1.hour))
    assert r = @c.renderer
    assert_equal Calendar::Display::Week::Day::DayRenderer, r.class
    assert_equal 2, r.object[:events].size # 1 event + empty space at the end
    assert_equal TestEvent::TestEventRenderer, r.object[:events][0].class
    assert_equal Calendar::Event::Empty::EmptyRenderer, r.object[:events][1].class
  end

  test "add overlapping events" do
    curt = @start_date
    endt = curt + 3.hours
    while (curt < endt)
      @c << TestEvent.new(curt, curt + 2.hours)
      curt += 1.hour
    end
    assert_equal 1, @c.size
    assert_equal Calendar::Event::Group, @c[0].class
    assert_equal 3, @c[0].size
    assert_equal 3, @c[0].columns.size
    @c[0].columns.each { |e| assert_equal Calendar::Event::Column, e.class }
  end

  test "render day with disjointed events" do
    curt = @start_date
    while (curt < @end_date)
      @c << TestEvent.new(curt, curt + 1.hour)
      curt += 2.hours
    end
    r = @c.renderer
    idx = 0
    while (idx < r.object.size)
      assert_equal TestEvent::TestEventRenderer, r.object[:events][idx].class
      idx += 1
      assert_equal Calendar::Event::Empty::EmptyRenderer, r.object[:events][idx].class
      idx += 1
    end
  end

end
