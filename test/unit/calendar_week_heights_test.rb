#
# $Id: calendar_week_heights_test.rb 214 2010-02-10 10:40:51Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarWeekHeightsTest < ActiveSupport::TestCase

  fixtures :topics, :activated_topics

  include Calendar::Display::Week::Methods

  def setup
    now = Time.zone.now
    assert @date_start = Time.zone.local(now.year, now.month, now.day, 8, 0)
    assert @at = activated_topics(:informatica_year_one)
  end

  #
  # row header has 2 borders top and bottom which are 1 pixel each, which
  # should be subtracted when calculating height
  #
  test "row header height" do
    assert ds = @date_start
    assert de = ds + (cell_time * 2).minutes # 30 minutes
    assert should_be = (row_height * 2) - 2 # twice the row height + 2 pixels for borders
    assert rh = Calendar::Display::Week::RowHeaderEvent.new(ds, de)
    assert_equal should_be, rh.height
  end

  #
  # empty cells have no borders, so they should get the full row height
  #
  test "empty cell height" do
    assert ds = @date_start
    assert de = ds + (cell_time * 2).minutes # 30 minutes
    assert should_be = row_height * 2
    assert ee = Calendar::Event::Empty.new(ds, de)
    assert_equal should_be, ee.height
  end

  #
  # lessons have borders, so they should get the full row height - 2 pixels
  #
  test "lesson cell height" do
    assert ds = @date_start
    assert n_cells = 4
    assert dur = (cell_time * n_cells) # 15 x 4 = 60 (minutes)
    assert should_be = (row_height * n_cells) - 2
    assert l = Lesson.new(:activated_topic => @at, :start_date => ds, :duration => dur)
    assert l.valid?
    assert_equal should_be, l.height
  end

  #
  # event groups must be tested in rendering, because they set up empty cells
  # only then
  #
  test "event groups height" do
    assert ds = @date_start
    assert n_cells = 8
    assert dur = (cell_time * n_cells) # 15 x 8 = 120 (minutes)
    assert step = 15.minutes
    assert num_lessons = 4
    lessons = []
    0.upto(num_lessons-1) do
      |n|
      lessons << Lesson.new(:activated_topic => @at, :start_date => ds + n*step, :duration => dur)
    end
    assert eg = Calendar::Event::Group.new
    lessons.each { |l| eg << l }
    assert r = eg.renderer
    eg_height_should_be = ((n_cells + num_lessons - 1) * row_height)
    assert_equal eg_height_should_be, r.object[:group].height
    r.object[:columns][1..r.object[:columns].size-1].each_with_index do
      |col, idx|
      empty_space_height_should_be = (idx + 1) * row_height
      assert_equal empty_space_height_should_be, col[:events][0].object.height
    end
  end

end
