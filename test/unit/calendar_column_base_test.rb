#
# $Id: calendar_column_base_test.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarColumnBaseTest < ActiveSupport::TestCase

  test "adding elements to column" do
    assert scalar = "This is a scalar element"
    assert array = scalar.split
    assert c = Calendar::Column::Base.new
    assert c << scalar
    assert_equal 1, c.size
    assert d = Calendar::Column::Base.new
    assert d << array
    assert_equal array.size, d.size
    assert another_array = [0, 1, 2, 3]
    assert d << another_array
    assert_equal array.size + another_array.size, d.size
  end

end
