#
# $Id: age_helper.rb 113 2009-10-20 01:51:42Z nicb $
#

module AgeHelper

  DEFAULT_OLD_AGE = 3.years.ago

  def old?
    return age < DEFAULT_OLD_AGE
  end

protected

  def age
    raise(NoMethodError, "protected method \"age\" must be implemented for #{self.class.name} for method \"old?\" to work (must return a Time.zone object)")
  end

  def _age(year)
    return Time.zone.local(year, 11, 1) # academic year start
  end

end
