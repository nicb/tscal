#
# $Id: day_base.rb 201 2010-01-04 04:32:03Z nicb $
#

module Calendar
  
  module Display

    module Week

		  class DayBase < Event::Column

        attr_reader :day_start, :day_end, :duration
		
		    def initialize(day)
          #
          # make sure that we're at the beginning of the day
          #
          beg_of_day = Time.zone.local(day.year, day.month, day.day)
          @day_start = beg_of_day + DAY_HOUR_START.hours
          @day_end   = beg_of_day + DAY_HOUR_END.hours
          @duration = ((@day_end - @day_start).to_f / 60.0).round
		    end

		  end

    end

  end

end
