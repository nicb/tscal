#
# $Id: base_methods.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'calendarable'

module Calendar

  module Event

		module BaseMethods
		
		  include Calendarable
      include InstanceMethods

      class PureVirtualMethodCalled < StandardError
      end
		
		  attr_accessor :start_date, :end_date, :duration
		
      def end_date=(ed)
        self.raw_end_date = ed
        @duration = to_minutes(self.end_date.to_i - self.start_date.to_i).round
      end

      def start_date=(sd)
        self.raw_start_date = sd
        self.raw_end_date = self.start_date + self.duration.minutes
      end

    protected

		  def initialize_base(sd, ed)
        self.raw_start_date = sd
        self.end_date = ed
		  end
		
		  def raw_start_date=(sd)
		    @start_date = sd
		  end

		  def raw_end_date=(sd)
        @end_date = sd
		  end

    private

      def to_minutes(time_diff) # time difference in seconds, not rounded
        return time_diff.to_f / 60.0
      end
		
	  end

  end

end
