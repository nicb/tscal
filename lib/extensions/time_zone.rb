#
# $Id: time_zone.rb 194 2009-12-15 02:57:41Z nicb $
#

module ActiveSupport

  class TimeZone

    class InvalidDate < ArgumentError
    end
    #
    # verified_local is a wrapped form for local which will first make sure
    # that the date is valid by creating a DateTime. DateTime will raise an
    # exception for dates like February 31st & the like, while Time.zone will
    # not. Thus this wrapper.
    #
    def verified_local(year, month = 1, day = 1, hour = 0, min = 0, sec = 0, msec = 0)
      begin
        DateTime.civil(year, month, day, hour, min, sec, msec) # this will raise an ArgumentError exception if wrong
      rescue ArgumentError
        raise(InvalidDate, "#{day}/#{month}/#{year}")
      end
      return local(year, month, day, hour, min, sec, msec)
    end

		def create_from_hash(h, options = {})
			keys = options.has_key?(:keys) ? options[:keys] : [ 'start_date(1i)', 'start_date(2i)', 'start_date(3i)', 'hour', 'minute', 'second' ]
      defaults = [ nil, 1, 1, 0, 0, 0 ]
      args_a = []
      keys.each_index do
        |i|
        arg = h.has_key?(keys[i]) ? h[keys[i]].to_i : defaults[i]
        args_a << arg.to_s
      end
      args = args_a.join(', ')
			return eval("verified_local(#{args})")
		end

  end

end
