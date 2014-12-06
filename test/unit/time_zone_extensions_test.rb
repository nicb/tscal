#
# $Id: time_zone_extensions_test.rb 192 2009-12-14 22:49:48Z nicb $
#
require 'test/test_helper'

require 'time_zone'

class TimeZoneExtensionsTest < ActiveSupport::TestCase

  def setup
    @default_args = [ 'start_date(1i)', 'start_date(2i)', 'start_date(3i)', 'hour', 'minute', 'second']
  end

  test "create_from_hash" do
    assert r = Time.zone.local(2010, 2, 27, 9, 23, 42)
    k = @default_args.dup
    h = { k[0] => r.year.to_s, k[1] => r.month.to_s, k[2] => r.day.to_s, k[3] => r.hour.to_s, k[4] => r.min.to_s, k[5] => r.sec.to_s }
    assert d = Time.zone.create_from_hash(h)
    assert_equal r, d
    arg = {}
    narg = []
    k.each do
      |key|
      arg.update(key => h[key])
      narg << h[key] 
      sarg = narg.join(', ')
      assert r = eval("Time.zone.local(#{sarg})")
      assert d = Time.zone.create_from_hash(arg)
      assert_equal r, d
    end
    arg[k[2]] = 31 # wrong day, February 31st
    assert_raise(ActiveSupport::TimeZone::InvalidDate) { Time.zone.create_from_hash(arg) } # wrong date
  end

  test "verified_local" do
    assert r = Time.zone.local(2010, 2, 27)
    assert d = Time.zone.verified_local(r.year, r.month, r.day) # correct date
    assert_equal r, d
    assert_raise(ActiveSupport::TimeZone::InvalidDate) { Time.zone.verified_local(r.year, r.month, 31) } # wrong date
  end

  test "avoiding octal digit errors" do
    k = @default_args.dup
    h = {}
    k.each { |key| h.update(key => '09') }
    narg = []
    k.each { |key| narg << h[key].to_i.to_s }
    sarg = narg.join(', ')
    assert r = eval("Time.zone.local(#{sarg})")
    assert d = Time.zone.create_from_hash(h)
    assert_equal r, d
  end

end
