#
# $Id: array.rb 192 2009-12-14 22:49:48Z nicb $
#

class Array

  def numeric_sort
    return sort { |a, b| a.to_i <=> b.to_i }
  end

end
