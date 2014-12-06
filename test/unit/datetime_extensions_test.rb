#
# $Id: datetime_extensions_test.rb 269 2011-03-03 17:20:26Z nicb $
#
require 'test/test_helper'

require 'datetime'

class DateTimeExtensions < ActiveSupport::TestCase

  fixtures :blacklisted_dates

  def setup
    @fixed_year = 2009
    @cur_year = Time.zone.now.year
    @next_year = @cur_year + 1
  end
  
  def test_next_available_day
    # martedì 21
    assert t = Time.zone.local(@fixed_year,07,21)
    wdays = ["Giovedì", "Sabato"]
    correct_wday = ActiveSupport::TimeWithZone.italian_to_wday(wdays[0])
    faday = t.next_available_day(wdays)
    assert_equal correct_wday, faday.wday
    assert faday >= t
  end

  def test_next_available_day_changing_month_31
    # domenica 30 agosto
    assert t = Time.zone.local(@fixed_year,8,30)
    wdays = ["Giovedì", "Sabato"]
    correct_wday = ActiveSupport::TimeWithZone.italian_to_wday(wdays[0])
    faday = t.next_available_day(wdays)
    assert_equal correct_wday, faday.wday
    assert faday >= t
    assert rd = Time.zone.local(@fixed_year,9,03)
    assert rd == faday
  end
  
  def test_next_available_day_changing_month_31
    # February 27, 2010
    assert test_year = @fixed_year + 1
    assert t = Time.zone.local(test_year,02,27)
    wdays = ["Giovedì", "Venerdì"]
    correct_wday = ActiveSupport::TimeWithZone.italian_to_wday(wdays[0])
    faday = t.next_available_day(wdays)
    assert_equal correct_wday, faday.wday, "for day #{faday}"
    assert faday >= t
    assert rd = Time.zone.local(test_year,03,04)
    assert rd == faday
  end
  
  def test_next_available_day_starting_on_a_blacklisted_day
    # Thursday 24/12/2009
    # christmas list
    assert t = Time.zone.local(@fixed_year,12,24)
    wdays = ["Giovedì", "Venerdì"]
    correct_wday = ActiveSupport::TimeWithZone.italian_to_wday(wdays[0])
    faday = t.next_available_day(wdays)
    assert_equal correct_wday, faday.wday
    assert faday >= t
    assert rd = Time.zone.local(@fixed_year + 1,1,7)
    assert rd == faday
  end
  
  def test_next_available_day_starting_on_a_non_blacklisted_good_day
    # venerdì 16 ottobre 2009
    # no blacklist into this range of lessons
    assert t = Time.zone.local(@fixed_year,10,16)
    wdays = ["Lunedì", "Venerdì"]
    correct_wday = ActiveSupport::TimeWithZone.italian_to_wday(wdays[1])
    faday = t.next_available_day(wdays)
    assert_equal correct_wday, faday.wday
    assert faday >= t
    assert rd = Time.zone.local(@fixed_year,10,16)
    assert rd == faday
  end
  
  def test_next_available_day_starting_just_before_a_month_of_blacklisted_days
    # Venerdì 8 gennaio, 2009
    # christmas blacklist
    assert t = Time.zone.local(@fixed_year,12,24)
    wdays = ["Mercoledì", "Venerdì"]
    correct_wday = ActiveSupport::TimeWithZone.italian_to_wday(wdays[1])
    faday = t.next_available_day(wdays)
    assert_equal correct_wday, faday.wday, "#{faday.to_s} is not the correct day"
    assert faday >= t
    assert rd = Time.zone.local(@fixed_year + 1,1,8)
    assert rd == faday, "#{rd.to_s} != #{faday.to_s}"
  end
  
  def test_empty_days
    # martedì 21
    assert t = Time.zone.local(@cur_year,07,21)
    wdays = []
    assert_raise(ActiveSupport::TimeWithZone::BadWdayArgument) do
      faday = t.next_available_day(wdays)
    end
  end

  def test_broken_date
    assert_raise(ArgumentError) do
      t = Time.zone.local(@next_year,6,32)
    end
  end
  
  def test_blacklisted
    assert bls = BlacklistedDate.all
    bls.each do
      |bl|
      assert d = Time.zone.at(bl.blacklisted.to_i)
      assert d.blacklisted?, "#{d} should be blacklisted and it is not"
    end
  end

  def test_blacklisting_on_all_possible_year_dates
    BlacklistedDate.delete_all
    assert_equal 0, BlacklistedDate.count
    assert sd = Time.zone.local(@next_year,1,1,3,0,0)
    0.upto(364).each do
      |delta|
      assert curdate = sd.since(delta.days)
      assert bld = BlacklistedDate.create(:blacklisted => curdate)
      assert bld.valid?
      assert curdate.blacklisted?, "#{curdate} should be blacklisted and it is not"
      #
      assert bld.destroy
      assert bld.frozen?
      assert !curdate.blacklisted?, "#{curdate} should NOT be blacklisted and it is"
    end
  end

  def test_monday
    #
    # this must be done on a specific year so @cur_year cannot be used
    #
    assert last_monday = Time.zone.local(@fixed_year, 9, 7)
    assert next_monday = Time.zone.local(@fixed_year, 9, 14)
    assert sat = Time.zone.local(@fixed_year, 9, 12)
    assert 5, sat.wday # make sure we're on saturday
    assert sun = Time.zone.local(@fixed_year, 9, 13)
    assert 6, sun.wday # make sure we're on sunday
    assert_equal last_monday, sat.monday
    assert_equal next_monday, sun.monday
  end

  def test_floor
    #
    # test non-quantized time
    #
    assert ref = Time.zone.local(@cur_year, 9, 13, 13, 28, 11)
    assert ref_floored = Time.zone.local(@cur_year, 9, 13, 13, 15)
    assert_equal ref_floored, ref.floor
    #
    # test quantized limits
    #
    [0, 15, 30, 45].each do
      |m|
      assert ref = Time.zone.local(@cur_year, 9, 13, 13, m)
      assert_equal ref, ref.floor
    end
  end
end
