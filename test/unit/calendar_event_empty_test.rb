#
# $Id: calendar_event_empty_test.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarEventEmptyTest < ActiveSupport::TestCase

  def setup
    @sd = Time.zone.local(2009, 12, 22, 8, 0)
    @sd_today = Time.zone.now
  end

  include Calendar::Display::Week::Methods

  test "empty event attributes with standard args" do
    ed = @sd + 30.minutes # 1 slot
    assert ee = Calendar::Event::Empty.new(@sd, ed)
    height_should_be = row_height * 2
    assert_equal height_should_be, ee.height
  end

  test "empty event div_name" do
    #
    # not today
    #
    tests = [
      { :should_be => 'cell_empty', :start_date => @sd },
      { :should_be => 'cell_empty_today', :start_date => @sd_today },
    ]
    tests.each do
      |h|
      ed = h[:start_date] + 30.minutes # 1 slot
      assert ee = Calendar::Event::Empty.new(h[:start_date], ed)
      assert_equal h[:should_be], ee.div_name
    end
  end

end
