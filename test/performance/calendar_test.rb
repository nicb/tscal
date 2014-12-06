#
# $Id: calendar_test.rb 217 2010-02-20 07:00:37Z nicb $
#
require 'test/test_helper'
require 'performance_test_help'

require 'test/utilities/string_helper'
require 'test/utilities/lesson_helper'

class CalendarTest < ActionController::PerformanceTest

  fixtures :all

  def setup
    assert @csy = course_starting_years(:tds_one)
    assert @teacher = users(:nicb)
    assert @num_lessons = 6 # one one-hour lesson per day, a full course in a week
    #
    # make sure you don't do tests on weeks that have blacklisted dates!
    # start from a fixed point: November 11 2009
    #
    assert @start_date = Time.zone.local(2009,11,9).monday + 9.hours
    assert @end_date = @start_date.since(6.days + 11.hours)
    assert @lesson_args = create_lesson_args(@start_date, '60')
    assert_equal ActiveSupport::TimeWithZone::WDAY_MAP.keys.size, @lesson_args.keys.size
    assert @lessons = create_many_lessons(54, 6, @start_date, @end_date)
  end

  def test_calendar_show
    assert_routing "calendar/show/#{@start_date.day}/#{@start_date.month}/#{@start_date.year}", { :controller => 'calendar', :action => 'show', :day => @start_date.day.to_s, :month => @start_date.month.to_s, :year => @start_date.year.to_s }
    get url_for(:controller => 'calendar', :action => 'show', :day => @start_date.day.to_s, :month => @start_date.month.to_s, :year => @start_date.year.to_s)
    assert_response :success
    assert_template :show
  end

private

  require 'string'

  include Test::Utilities::StringHelper
  include Test::Utilities::LessonHelper

end
