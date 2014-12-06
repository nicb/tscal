#
# $Id: blacklisted_date_test.rb 269 2011-03-03 17:20:26Z nicb $
#
require 'test/test_helper'

class BlacklistedDateTest < ActiveSupport::TestCase

  def setup
    BlacklistedDate.delete_all
  end

  test "creation and destroy" do
    assert d = Time.zone.local(2009, 12, 25)
    assert normalized_d = Time.zone.local(d.year, d.month, d.day, 3, 0, 0)
    assert b = BlacklistedDate.create(:blacklisted => d)
    assert b.valid?
    assert_equal normalized_d, b.blacklisted
    assert b.destroy
    assert b.frozen?
  end
  
  test "validations" do
    assert date = Time.zone.local(2009,12,25, 3, 0, 0)
    assert description = "Natale"
    assert b = BlacklistedDate.create()
    assert !b.valid?
    assert b = BlacklistedDate.create(:blacklisted => date, :description => description)
    assert b.valid?
    assert c = BlacklistedDate.create(:blacklisted => date, :description => description)
    assert !c.valid?
  end

  test "uniqueness deep test" do
    assert date1 = Time.zone.local(2009,12,25, 3, 0, 0)
    assert date2 = Time.zone.local(2009,12,25, 3, 15, 0) # same day but another time
    assert description = "Natale"
    assert b = BlacklistedDate.create(:blacklisted => date1, :description => description)
    assert b.valid?
    assert c = BlacklistedDate.create(:blacklisted => date1, :description => description)
    assert !c.valid?
    assert d = BlacklistedDate.create(:blacklisted => date2, :description => description)
    assert !d.valid?
  end
  
  test "attributes" do
    #BlacklistedDate.delete_all
    assert date = Time.zone.local(2009,12,25)
    assert date_norm = Time.zone.local(date.year, date.month, date.day, 3, 0, 0)
    assert date2 = Time.zone.local(2009,12,31)
    assert description = "Natale"
    assert b = BlacklistedDate.create(:blacklisted => date, :description => description)
    assert b.valid?
    assert_equal date_norm, b.blacklisted
    assert_equal description, b.description
    assert c = BlacklistedDate.create(:blacklisted => date2)
    assert c.valid?
    assert c.reload
    assert "Il conservatorio è chiuso", c.description
  end

end
