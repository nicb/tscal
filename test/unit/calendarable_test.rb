#
# $Id: calendarable_test.rb 290 2012-07-31 01:45:43Z nicb $
#
require 'test/test_helper'

class CalendarableTest < ActiveSupport::TestCase
  
  class UnpreparedClass
    include Calendarable
  end

  require File.dirname(__FILE__) + '/calendarable_mock'

  def setup
    ActiveRecord::Migration.verbose = false
    CreateCalendarableMock.up
    assert @calendarable_pv_methods = [ :start_date, :end_date, :topic_display, :topic_display_tooltip,
      :course_display, :course_display_tooltip ]
  end

  def teardown
    ActiveRecord::Migration.verbose = false
    CreateCalendarableMock.down
  end

  def test_creation_destruction
    dur = 120
    assert cc = CalendarableMock.create(:start_date => Time.zone.now, :duration => dur)
    assert cc.valid?
    #
    assert cc.destroy
    assert cc.frozen?
  end

  def test_lack_of_methods
    assert uc = UnpreparedClass.new
    @calendarable_pv_methods.each do
      |m|
      assert uc.respond_to?(m)
      assert_raise(Calendarable::MethodNotImplemented) { uc.send(m) }
    end
  end

  def test_presence_of_methods
    dur = 120
    assert pc = CalendarableMock.create(:start_date => Time.zone.now, :duration => dur)
    @calendarable_pv_methods.each do
      |m|
      assert pc.respond_to?(m), "Method #{m.to_s}"
      assert pc.send(m), "Method #{m.to_s}"
    end
    assert_equal ActiveSupport::TimeWithZone, pc.start_date.class
    assert_equal (pc.start_date + dur.minutes).to_i, pc.end_date.to_i
    assert_equal pc.start_date.to_s + '-' + pc.end_date.to_s, pc.topic_display
  end

  def test_find_overlaps
    assert dur = 120 # minutes
    assert durm = dur.minutes
    assert sd = Time.zone.now
    assert ref = CalendarableMock.create(:start_date => sd, :duration => dur)
    assert ref.valid?
		assert ref.duration > 0, "CalendarableMock #{ref.inspect} duration is #{ref.duration} - something wrong here"
		assert_equal dur, ref.duration
    cms =
    [
      { :args => { :start_date => (sd - (durm * 2)), :duration => dur }, :bool => false }, # much before
      { :args => { :start_date => (sd - (durm / 2)), :duration => dur }, :bool => true }, # before
      { :args => { :start_date => (sd + (durm / 2)), :duration => dur }, :bool => true }, # after
      { :args => { :start_date => (sd + (durm / 10)), :duration => (dur-100) }, :bool => true }, # inner
      { :args => { :start_date => (sd - (durm / 10)), :duration => (dur*2) }, :bool => true }, # outer
      { :args => { :start_date => sd, :duration => dur }, :bool => true }, # equal
      { :args => { :start_date => (sd + (durm * 2)), :duration => dur }, :bool => false }, # much after
    ]
	  cms.each do
	    |cm|
	    assert cf = CalendarableMock.create(cm[:args])
	    assert cf.valid?
	    assert_equal cm[:bool], ref.find_overlaps.index(cf) != nil
	    assert_equal cm[:bool], cf.find_overlaps.index(ref) != nil
	    assert cf.destroy
	    assert cf.frozen?
	  end
  end

  def test_overlaps
    assert dur = 120 # minutes
    assert durm = dur.minutes
    assert sd = Time.zone.now
    assert ref = CalendarableMock.new(:start_date => sd, :duration => dur)
    cms =
    [
      { :args => { :start_date => (sd - (durm * 2)), :duration => dur }, :bool => false }, # much before
      { :args => { :start_date => (sd - (durm / 2)), :duration => dur }, :bool => true }, # before
      { :args => { :start_date => (sd + (durm / 2)), :duration => dur }, :bool => true }, # after
      { :args => { :start_date => (sd + (durm / 10)), :duration => (dur-100) }, :bool => true }, # inner
      { :args => { :start_date => (sd - (durm / 10)), :duration => (dur*2) }, :bool => true }, # outer
      { :args => { :start_date => sd, :duration => dur }, :bool => true }, # equal
      { :args => { :start_date => (sd + (durm * 2)), :duration => dur }, :bool => false }, # much after
    ]
	  cms.each do
	    |cm|
	    assert cf = CalendarableMock.new(cm[:args])
	    assert_equal cm[:bool], ref.overlaps?(cf)
	    assert_equal cm[:bool], cf.overlaps?(ref)
	  end
  end

	test "unordered update of attributes" do
		#
		# this tests race conditions, so it should be done more than once to make
		# sure it runs correctly
		#
		1.upto(100) do
			|n|
      assert dur = 120 # minutes
      assert durm = dur.minutes
      assert sd = Time.zone.now
      assert ref = CalendarableMock.new(:start_date => sd, :duration => dur)
  		cms_diffs =
  		[
  			{ :start_date => (-(durm * 2)), :duration => dur },
  			{ :start_date => (-(durm / 2)), :duration => dur },
  			{ :start_date => (-(durm / 10)), :duration => (dur-100) },
  			{ :start_date => (-(durm / 10)), :duration => (dur * 2) },
  			{ :start_date => (durm * 2), :duration => dur },
  		]
  		cms_diffs.each do
  			|cm_diff|
  			assert new_sd = sd + cm_diff[:start_date]
  			assert new_ed = new_sd + cm_diff[:duration].minutes
  			assert ref.update_attributes!(:duration => cm_diff[:duration], :start_date => new_sd)
  			assert_equal new_sd, ref.start_date
  			assert_equal new_ed, ref.end_date
  			assert_equal cm_diff[:duration], ref.duration
  		end
		end
	end

end
