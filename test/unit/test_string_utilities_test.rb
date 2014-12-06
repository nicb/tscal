#
# $Id: test_string_utilities_test.rb 217 2010-02-20 07:00:37Z nicb $
#
require 'test/test_helper'
require 'test/utilities/string_helper'

class TestStringUtilitiesTest < Test::Unit::TestCase

  include Test::Utilities::StringHelper

  def test_size_of_strings
    1.upto(20) do
      |min|
	    (min+1).upto(50) do
	      |max|
	      abs_max = min + max
	      max = (rand() * abs_max.to_f).ceil + min
        assert s = random_string(min, max)
        assert s.size >= min && s.size < max, "String \"#{s}\" does not conform to requirements (size(#{s.size}) >= #{min} && size(#{s.size}) < #{max})"
      end
    end
  end

  def test_argument_errors
    2.upto(100) do
      |min|
      0.upto(min-1) do
        |max|
        assert_raise(ArgumentError) { random_string(min, max) }
      end
    end
  end

end
