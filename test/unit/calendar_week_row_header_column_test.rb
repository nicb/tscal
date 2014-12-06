#
# $Id: calendar_week_row_header_column_test.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarWeekRowHeaderColumnTest < ActiveSupport::TestCase

  include Calendar::Display::Week::Methods

  def setup
    assert @day = Time.zone.local(2009, 12, 14)
    assert @start_date = @day + DAY_HOUR_START.hours
    assert @end_date = @day + DAY_HOUR_END.hours
    assert_equal 1, @start_date.wday
    assert_equal 1, @end_date.wday
    assert @c = Calendar::Display::Week::RowHeader.new(@day)
  end

  test "column header start and day end" do
    assert_equal @start_date, @c.day_start
    assert_equal @end_date, @c.day_end
  end

  test "number of elements for column header" do
    should_be = (@c.day_end - @c.day_start) / (@c.cell_time * DEFAULT_ROW_SPAN).minutes
    assert_equal should_be, @c.size
  end

  test "make sure we've got the right objects" do
    @c.each { |e| assert_equal Calendar::Display::Week::RowHeaderEvent, e.class }
  end

  test "render the row header" do
    assert r = @c.renderer
    assert_equal @start_date, @c.day_start
    assert_equal Calendar::Display::Week::RowHeader::RowHeaderRenderer, r.class
    cur = @start_date
    step = (@c.cell_time * DEFAULT_ROW_SPAN).minutes
    r.object.each do
      |rher|
      assert_equal Calendar::Display::Week::RowHeaderEvent::RowHeaderEventRenderer, rher.class
      assert_equal Calendar::Display::Week::RowHeaderEvent, rher.object.class
      assert_equal cur, rher.object.start_date
      cur += step
      assert_equal cur, rher.object.end_date
    end
  end

end
