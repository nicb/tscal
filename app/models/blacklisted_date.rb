#
# $Id: blacklisted_date.rb 269 2011-03-03 17:20:26Z nicb $
#
class BlacklistedDate < ActiveRecord::Base

  validates_presence_of :blacklisted

  #
  # we normalize all dates to be at the same hour (*not* around midnight to
  # avoid possible time zone hysteresis) so that we compare dates, really.
  #
  def initialize(parms = {})
    if parms && parms.has_key?(:blacklisted) && parms[:blacklisted] && parms[:blacklisted].is_a?(Time)
      t = parms[:blacklisted]
      parms[:blacklisted] = Time.zone.local(t.year, t.month, t.day, 3, 0, 0)
    end
    super(parms)
  end

  def unique?
    found = self.class.like_without_validation(self.read_attribute('blacklisted'))
    !(found.size > 1)
  end

  def validate
    #
    # :blacklisted gets a special treatment
    #
    if self.blacklisted
      errors.add(:blacklisted, 'must be unique') unless unique?
    else
      errors.add(:blackisted, "can't be blank")
    end
  end

  class << self

	  class UnknownBlacklistedDateFormat < StandardError; end
	
	  def like(date)
      bd = like_without_validation(date)
	    return bd && bd.valid? ? true : false
	  end

    #
    # +like_without_validation(date)+ is required to perform the search
    # without validation (otherwise it would deadlock in validations)
    #
    def like_without_validation(date)
	    datestring = case date
	                 when Time, DateTime, ActiveSupport::TimeWithZone : date.to_date.to_s
	                 when String : date
	                 else raise(UnknownBlacklistedDateFormat, "#{date.inspect}")
	                 end
	    BlacklistedDate.all(:conditions => ['blacklisted like ?', "#{datestring}%"])
    end

  end

end
