#
# $Id: fixnum.rb 116 2009-10-20 21:43:47Z nicb $
#

class Fixnum

private

  def to_var_s(lz)
    return sprintf("%0*d", lz, self)
  end

public

  def to_ss
    return to_var_s(2)
  end

  def to_sss
    return to_var_s(3)
  end

  def to_ssss
    return to_var_s(4)
  end

end
