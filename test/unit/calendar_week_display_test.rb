#
# $Id: calendar_week_display_test.rb 215 2010-02-20 04:56:54Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarWeekDisplayTest < ActiveSupport::TestCase

  class TestEvent
    include Calendar::Event::BaseMethods
    include Calendar::Display::Render
    has_renderer

    def initialize(ds, de)
      initialize_base(ds, de)
    end
  end

  include Calendar::Display::Week::Methods

  def setup
    assert @day = Time.zone.local(2009, 12, 13)
    assert @start_date = @day.monday + DAY_HOUR_START.hour
    assert @end_date = @day.monday + 5.days + DAY_HOUR_END.hour
    assert_equal 1, @start_date.wday
    assert_equal 6, @end_date.wday
    assert @c = Calendar::Display::Week::Display.new(@day)
  end

  test "day start and day end" do
    assert_equal @start_date, @c.week_start
    assert_equal @end_date, @c.week_end
  end

  test "add regular data set with non-overlapping events and render" do
    data_set = []
    0.upto(@c.days.size-1) do
      |i|
      data_set[i] = []
      data_set[i] << TestEvent.new(@c.days[i].day_start, @c.days[i].day_start + 2.hours)
      data_set[i] << TestEvent.new(@c.days[i].day_start + 3.hours, @c.days[i].day_start + 5.hours)
    end
    assert @c.add_data_set(data_set)
    @c.days.each { |d| assert_equal 2, d.size }
    @c.days.each { |d| d.each { |e| assert_equal TestEvent, e.class }}
    #
    # render
    #
    assert r = @c.renderer
    assert_equal Calendar::Display::Week::Display::DisplayRenderer, r.class
    assert_equal Array, r.object.class
    assert_equal 7, num = r.object.size # 6 days in a week (Mon-Sat)
    assert_equal Calendar::Display::Week::RowHeader::RowHeaderRenderer, r.object[0].class
    r.object[1..r.object.size-1].each { |d| assert_equal Calendar::Display::Week::Day::DayRenderer, d.class }
  end

  test "add regular data set with overlapping events" do
    data_set = []
    0.upto(@c.days.size-1) do
      |i|
      data_set[i] = []
      data_set[i] << TestEvent.new(@c.days[i].day_start, @c.days[i].day_start + 2.hours)
      data_set[i] << TestEvent.new(@c.days[i].day_start + 30.minutes, @c.days[i].day_start + 5.hours)
    end
    assert @c.add_data_set(data_set)
    @c.days.each { |d| assert_equal 1, d.size }
    @c.days.each { |d| d.each { |e| assert_equal Calendar::Event::Group, e.class }}
    #
    # render
    #
    assert r = @c.renderer
    assert_equal Calendar::Display::Week::Display::DisplayRenderer, r.class
    assert_equal Array, r.object.class
    assert_equal 7, num = r.object.size # A header column + 6 days in a week (Mon-Sat)
    assert_equal Calendar::Display::Week::RowHeader::RowHeaderRenderer, r.object[0].class
    r.object[1..r.object.size-1].each do
      |d|
      assert_equal Calendar::Display::Week::Day::DayRenderer, d.class
      assert_equal 2, d.object[:events].size # 1 Event Group + 1 Empty event
      assert_equal Calendar::Event::Group::GroupRenderer, d.object[:events][0].class
      assert_equal Calendar::Event::Empty::EmptyRenderer, d.object[:events][1].class
    end
  end

  test "add irregular data set with non-time-ordered events" do
    data_set = []
    0.upto(@c.days.size-1) do
      |i|
      data_set[i] = []
      data_set[i] << TestEvent.new(@c.days[i].day_start + 3.hours, @c.days[i].day_start + 5.hours)
      data_set[i] << TestEvent.new(@c.days[i].day_start, @c.days[i].day_start + 5.hours)
    end
    assert_raise(Calendar::Event::Column::NonTimeOrderedEvent) {  @c.add_data_set(data_set) }
  end

  test "add irregular data set with events outside of range" do
    data_set = []
    0.upto(@c.days.size-1) do
      |i|
      data_set[i] = []
      data_set[i] << TestEvent.new(@c.days[i].day_start - 1.hour, @c.days[i].day_end + 1.hour)
      data_set[i] << TestEvent.new(@c.days[i].day_start + 3.hours, @c.days[i].day_start + 5.hours)
    end
    assert_raise(Calendar::Display::Week::Display::EventDateMismatch) {  @c.add_data_set(data_set) }
  end

  test "add irregular (mismatching) data set" do
    data_set = []
    0.upto(@c.days.size-2) do
      |i|
      data_set[i] = []
      data_set[i] << TestEvent.new(@c.days[i].day_start + 1.hour, @c.days[i].day_end + 2.hour)
      data_set[i] << TestEvent.new(@c.days[i].day_start + 3.hours, @c.days[i].day_start + 5.hours)
    end
    assert_raise(Calendar::Display::Week::Display::DataSetSizeMismatch) {  @c.add_data_set(data_set) }
  end

  test "row header specials" do
    first = @c.days.first
    last  = @c.days.last
    second = @c.days[1]
    assert_equal 'first', @c.row_header_special(first)
    assert_equal 'last',  @c.row_header_special(last)
    @c.days[1..-2].each do
      |d|
      assert_equal '',      @c.row_header_special(d)
    end
  end

end
