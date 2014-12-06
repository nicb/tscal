#
# $Id: calendar_controller_test.rb 245 2010-03-15 14:43:37Z mtisi $
#

#TODO: duplicate the test with show_html and show_js

require 'test/test_helper'

require 'test/utilities/string_helper'
require 'test/utilities/lesson_helper'

class CalendarControllerTest < ActionController::TestCase

	fixtures :users, :topics, :course_starting_years, :activated_topics

	def setup
		assert @at = activated_topics(:informatica_year_one)
    assert @at.valid?, "Invalid Activated Topic: #{@at.errors.full_messages.join(', ')}"
		assert @at2 = activated_topics(:informatica_year_two), "Invalid Activated Topic: #{@at2.errors.full_messages.join(', ')}"
		assert @at3 = activated_topics(:pianoforte_year_one), "Invalid Activated Topic: #{@at3.errors.full_messages.join(', ')}"
    assert @y1 = 2009
	end

  include Test::Utilities::LessonHelper

  test "index" do
    assert_routing '/', { :controller => 'calendar', :action => 'show_js' }
    get :show_js

    assert_response :success
  end

  test "show" do
    how_many = 48
    sd = Time.zone.local(2010,2,15).monday + 9.hours
    ed = sd + 6.days + 11.hours
    res = create_many_lessons(how_many, 6, sd, ed)
    assert_routing '/html', { :controller => 'calendar', :action => 'show_html' }
    get :show_html, { :day => sd.day, :month => sd.month, :year => sd.year }

    assert_equal how_many, assert_select('div.event_group_inner_column').size
    assert_response :success
  end

  test "row header show" do
    #
    # test that lessons and event groups work well together. Make a first day
    # with an event group and a second day with a single lesson
    #
    dur = 60 # minutes
    sd1 = Time.zone.now.monday + 9.hours
    assert l1 = Lesson.create(:activated_topic => @at, :start_date => sd1, :duration => dur)
    assert l1.valid?, "Invalid Lesson: #{l1.errors.full_messages.join(', ')}"
    assert l2 = Lesson.create(:activated_topic => @at2, :start_date => sd1, :duration => dur * 2)
    assert l2.valid?, "Invalid Lesson: #{l2.errors.full_messages.join(', ')}"
    sd2 = sd1 + 1.day
    assert l3 = Lesson.create(:activated_topic => @at, :start_date => sd2, :duration => dur)
    assert l3.valid?, "Invalid Lesson: #{l3.errors.full_messages.join(', ')}"

    get :show_html

    assert_equal 3, assert_select('div.cell_lesson').size
    assert_response :success
  end

  include Calendar::Event::InstanceMethods

	def test_calendar_display_with_non_concurrent_lessons
    ds = Time.zone.now.monday + 8.hours
		assert cd = Calendar::Display::Week::Display.new(ds)
    cd.days.each do
      |day|
      day_height_should_be = (12.hours.to_f / cell_time.minutes.to_f).round * row_height 
      assert_equal day_height_should_be, day.height
    end
    clear_all_lessons
		lessons = [
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(ds.to_i), :duration => 90),
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at((ds + 1.day + 2.hours).to_i), :duration => 120),
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at((ds + 2.days + 4.hours).to_i), :duration => 240),]
		lessons.each {|l| assert l.valid?}
		assert num_tr = (cd.days[0].day_end.to_i - cd.days[0].day_start.to_i) / Calendar::Display::Week::Methods::DEFAULT_CELL_TIME.minutes
		get :show_html
		assert_response :success
    displayed_lessons = assert_select('div.cell_lesson').size
    assert_equal lessons.size, displayed_lessons
	end

  def test_routing
    #
    # proper routing
    #
    assert_routing 'html/23/11/2009', { :controller => 'calendar', :action => 'show_html', :day => '23', :month => '11', :year => '2009' }
    #
    # wrong routing (still handled, though)
    #
    assert_routing 'html/32/27/2009', { :controller => 'calendar', :action => 'show_html', :day => '32', :month => '27', :year => '2009' }
    #
    # no routing at all (still handled)

    assert_routing '/', { :controller => 'calendar', :action => 'show_js' }

    assert_routing '/html', { :controller => 'calendar', :action => 'show_html' }
  end

  test "auth filtering" do
    #
    # try getting the index without authorization
    #
    get :show_js
    assert_response :success
    #
    #TODO: change parameters to an hxr post with ajax, an duplicate with html
    #get :show_js, { :day => '18', :month => '10', :year => '2009' }
    #assert_response :success
  end

  test "calendar with lessons with invalid dates" do
    assert now = Time.zone.now.monday
		assert cd = Calendar::Display::Week::Display.new(now)
    clear_all_lessons
		lessons = [
		  Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 10.hours), :duration => 90), # right
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 1.hour), :duration => 120), # wrong
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 2.days), :duration => 240), # wrong
	  ]
		lessons.each {|l| assert l.valid?}
		get :show_js
		assert_response :success
    # should have one lesson only
    #TODO: adapt the select with the output code from jquery fullcalendar
    #n_lessons = assert_select('div.cell_lesson').size
    #assert_equal 1, n_lessons
  end

  test "calendar with filtered lessons" do
    assert now = Time.zone.now.monday
		assert cd = Calendar::Display::Week::Display.new(now)
    clear_all_lessons
		lessons = [
		  Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 10.hours), :duration => 90),
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 14.hour), :duration => 120),
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 2.days + 10.hours), :duration => 240),
		  Lesson.create(:activated_topic => @at2, :start_date => Time.zone.at(now.to_i + 10.hours), :duration => 90),
			Lesson.create(:activated_topic => @at2, :start_date => Time.zone.at(now.to_i + 14.hour), :duration => 120),
			Lesson.create(:activated_topic => @at2, :start_date => Time.zone.at(now.to_i + 2.days + 10.hours), :duration => 240),
	  ]
		lessons.each {|l| assert l.valid?}
		get :show_html, { :filter => "ActivatedTopic.#{@at2.id}" }
		assert_response :success
    n_lessons = assert_select('div.cell_lesson').size
    assert_equal 3, n_lessons
  end

  test "js calendar with course filtered lessons" do
    assert now = Time.zone.now.monday
		assert cd = Calendar::Display::Week::Display.new(now)
    clear_all_lessons
		lessons = [
		  Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 10.hours), :duration => 90),
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 14.hour), :duration => 120),
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 2.days + 10.hours), :duration => 240),
		  Lesson.create(:activated_topic => @at2, :start_date => Time.zone.at(now.to_i + 10.hours), :duration => 90),
			Lesson.create(:activated_topic => @at2, :start_date => Time.zone.at(now.to_i + 14.hour), :duration => 120),
			Lesson.create(:activated_topic => @at2, :start_date => Time.zone.at(now.to_i + 2.days + 10.hours), :duration => 240),
	  ]
		lessons.each {|l| assert l.valid?}
    assert course = courses(:tds)
    assert course.valid?
		xhr :get, :get_lessons_json, { :filter => "Course.#{course.id}", :start => cd.week_start, :end => cd.week_end }
		assert_response :success
    #
    # FIXME: we don't know what to test here in terms of output, since the output is
    # a JSON array
    #
    assert !@response.body.blank?
  end

  test "html calendar with course filtered lessons" do
    assert now = Time.zone.now.monday
		assert cd = Calendar::Display::Week::Display.new(now)
    clear_all_lessons
		lessons = [
		  Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 10.hours), :duration => 90),
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 14.hour), :duration => 120),
			Lesson.create(:activated_topic => @at, :start_date => Time.zone.at(now.to_i + 2.days + 10.hours), :duration => 240),
		  Lesson.create(:activated_topic => @at2, :start_date => Time.zone.at(now.to_i + 10.hours), :duration => 90),
			Lesson.create(:activated_topic => @at2, :start_date => Time.zone.at(now.to_i + 14.hour), :duration => 120),
			Lesson.create(:activated_topic => @at2, :start_date => Time.zone.at(now.to_i + 2.days + 10.hours), :duration => 240),
	  ]
		lessons.each {|l| assert l.valid?}
    assert course = courses(:tds)
    assert course.valid?
		get :show_html, { :filter => "Course.#{course.id}", :start => cd.week_start, :end => cd.week_end }
		assert_response :success
    n_lessons = assert_select('div.cell_lesson').size
    assert_equal 6, n_lessons
  end

  test "calendar with concurrent lessons" do
    assert now = Time.zone.now.monday + 10.hours
		assert cd = Calendar::Display::Week::Display.new(now)
    clear_all_lessons
    assert olaps_should_be = 2
    #
    # straightforward building
    #
    lstart = now + 2.hours
    assert ref = Lesson.create(:activated_topic => @at, :start_date => lstart, :duration => 120)
    assert ref.valid?
		get :show_html, { :day => now.day, :month => now.month, :year => now.year }
    assert_response :success
    assert_select('div.cell_lesson') do
      sel = assert_select("div.lesson_title")
      assert_equal 1, sel.size
      sel.each_with_index do
        |tag, idx|
        assert_equal ref.topic_display_tooltip, tag.attributes['title']
      end
    end
    assert olap_after = Lesson.create(:activated_topic => @at3, :start_date => lstart.since(30.minutes), :duration => 120)
    assert olap_after.valid?
    assert olap_after2 = Lesson.create(:activated_topic => @at3, :start_date => lstart.since(45.minutes), :duration => 120)
    assert olap_after2.valid?
		get :show_html, { :day => now.day, :month => now.month, :year => now.year }
    assert_response :success
    cmp = [ ref, olap_after, olap_after2 ]
    assert_select('div.event_group') do
      l = assert_select("div.cell_lesson")
      assert_equal cmp.size, l.size
      l.each do
	      tags = assert_select('div.lesson_title')
	      tags.each_with_index do
	        |tag, idx|
	        assert_equal cmp[idx].topic_display_tooltip, tag.attributes['title']
	      end
      end
    end
    #
    # clear
    #
    clear_all_lessons
    #
    # reverse building (second lesson)
    #
    assert ref = Lesson.create(:activated_topic => @at, :start_date => lstart, :duration => 120)
    assert ref.valid?
    assert olap_before = Lesson.create(:activated_topic => @at3, :start_date => lstart.since(-30.minutes), :duration => 120)
    assert olap_before.valid?
    assert olap_before2 = Lesson.create(:activated_topic => @at3, :start_date => lstart.since(-45.minutes), :duration => 120)
    assert olap_before2.valid?
		get :show_html, { :day => now.day, :month => now.month, :year => now.year }
    cmp = [ olap_before2, olap_before, ref ]
    assert_select('div.event_group') do
      l = assert_select("div.cell_lesson")
      assert_equal cmp.size, l.size
      l.each do
	      tags = assert_select('div.lesson_title')
	      tags.each_with_index do
	        |tag, idx|
	        assert_equal cmp[idx].topic_display_tooltip, tag.attributes['title']
	      end
      end
    end
  end

  test "show filtering with a course_starting_year with no lessons" do
    lstart = Time.zone.now.monday + 8.hours
    #
    # let's make sure we have a lesson in range
    #
    assert l = Lesson.create(:activated_topic => @at, :start_date => lstart + 3.hours, :duration => 120)
    assert l.valid?
    #
    # let's make a course_starting_year that has no lessons (should return
    # nothing)
    #
    assert course = Course.create(:name => 'Unknown', :acronym => 'UO', :duration => 3)
    assert course.valid?, "#{course.errors.full_messages.join(', ')}"
    assert csy = CourseStartingYear.create(:course => course, :starting_year => @y1, :color => '#ff00ff')
    assert csy.valid?
    #
    assert Lesson.all(:conditions => ['start_date >= ? and end_date <= ?', lstart.monday + 8.hours, lstart.monday + 5.days + 20.hours]).size > 0 # we've got lessons to show
    total_lessons = 0
    get :show_html, { :day => lstart.day, :month => lstart.month, :year => lstart.year, :filter => "CourseStartingYear.#{csy.id}" }
    assert_response :success
    assert_select 'div#calendar' do
      assert_select 'div#calendar_body' do
        assert_select 'div.column' do
          assert sel = css_select('div.cell_lesson')
          assert_equal 0, sel.size
          assert total_lessons += sel.size
        end
      end
    end
    assert_equal 0, total_lessons
    #
    # now let's try with no filter (should return everything available)
    #
    assert ((als = Lesson.all(:conditions => ['start_date >= ? and end_date <= ?', lstart.monday + 8.hours, lstart.monday + 6.days + 20.hours])).size) > 0 # we've got lessons to show
    total_lessons = 0
    get :show_html, { :day => als.first.start_date.day, :month => als.first.start_date.month, :year => als.first.start_date.year }
    assert_response :success
    assert_select 'div#calendar' do
      assert_select 'div#calendar_body' do
        assert_select 'div.column' do
          assert sel = assert_select('div.cell_lesson')
          assert total_lessons += sel.size
        end
      end
    end
    assert_equal als.size, total_lessons
  end

  test "calendar today background" do
    lstart = Time.zone.now
    flunk("Unfortunately this test does not work on sundays :(") if lstart.wday == 0
    get :show_html # this will show today's calendar
    assert_response :success
    assert_select('div.cell_empty_today')
  end

protected

  def clear_all_lessons
    Lesson.all.each { |l| assert l.destroy; assert l.frozen? }
    assert_equal 0, Lesson.all.size
    assert Lesson.all.blank?
  end

end
