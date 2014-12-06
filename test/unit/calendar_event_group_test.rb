#
# $Id: calendar_event_group_test.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarEventGroupTest < ActiveSupport::TestCase

  class TestEvent
    include Calendar::Event::BaseMethods
    include Calendar::Display::Render
    has_renderer

    def initialize(sd, ed)
      initialize_base(sd, ed)
    end
  end

  def setup
    @sd = Time.zone.local(2009, 12, 22, 8, 0)
    @ed = nil
    @evs = []
    @num_evs = 10
    0.upto(@num_evs - 1) do
      |i|
      stdt = @sd + (i * 30).minutes
      endt = @ed = stdt + 120.minutes
      @evs << TestEvent.new(stdt, endt)
    end
    assert_equal @num_evs, @evs.size
  end

  include Calendar::Display::Week::Methods

  test "inserting overlapping events" do
    assert eg = Calendar::Event::Group.new
    @evs.each { |e| eg << e }
    assert_equal @num_evs, eg.size
    assert_equal @sd, eg.start_date
    assert_equal @ed, eg.end_date
    height_should_be = (((@ed - @sd).to_f / 60.0) / cell_time.to_f).round * row_height # two pixels for border
    column_width_should_be = 100.0 / @num_evs.to_f
    assert_equal height_should_be, eg.height
    assert_equal column_width_should_be, eg.column_width
  end

  test "render overlapping events" do
    assert eg = Calendar::Event::Group.new
    @evs.each { |e| eg << e }
    assert r = eg.renderer
    assert_equal @num_evs, r.object[:columns].size
    assert_equal 2, r.object[:columns][0].size
    assert r.object[:columns][0][:events][0].class.name =~ /TestEvent::TestEventRenderer/
    assert r.object[:columns][0][:events][1].class.name =~ /Calendar::Event::Empty::EmptyRenderer/
    r.object[:columns][1..r.object.size-2].each do
      |col|
      assert_equal 3, col[:events].size
      [Calendar::Event::Empty::EmptyRenderer, TestEvent::TestEventRenderer, Calendar::Event::Empty::EmptyRenderer].each_with_index do
        |k, i|
        assert col[:events][i].class.name =~ /#{k}/
      end
    end
    assert r.object[:columns][r.object.size-1][:events][0].class.name =~ /Calendar::Event::Empty::EmptyRenderer/
    assert r.object[:columns][r.object.size-1][:events][1].class.name =~ /TestEvent::TestEventRenderer/
    assert_equal @sd, eg.start_date
    assert_equal @ed, eg.end_date
    height_should_be = (((eg.end_date - eg.start_date) / 60.0).round / cell_time) * row_height
    assert_equal height_should_be, eg.height
  end

end
