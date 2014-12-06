#
# $Id: utilities.rb 464 2009-10-14 19:59:50Z nicb $
#

module Test

  module Utilities

    module StringHelper

		  def random_string(min_size = 3, max_size = 30)
		    string = ''
	      raise(ArgumentError, "Max size of string (#{max_size}) <= min size (#{min_size})") unless max_size > min_size
	      size = (rand() * (max_size-min_size-1).to_f).ceil + min_size
		    0.upto(size-1) do  
		      string += ((rand() * (?z - ?a)).round + ?a).chr
		    end
		    return string.capitalize
		  end

    end

  end

end
