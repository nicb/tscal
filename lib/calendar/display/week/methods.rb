#
# $Id: methods.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'datetime'

module Calendar

  module Display

    module Week

      def self.calendar_template_path
        return 'calendar/week'
      end

      module Methods
		    #
		    # default behaviour of week calendar cells:
		    # +DEFAULT_CELL_TIME+ is the minimum time step observable in week views
		    # +DEFAULT_ROW_SPAN+ is the number of rows span by the header column
		    # +ROW_HEIGHT+ is the row height in pixels
		    #
		    DEFAULT_CELL_TIME = 15 # in minutes
		    DEFAULT_ROW_SPAN = 2 # calendar times are displayed each 30 mins (2 cells)
		    DEFAULT_ROW_HEIGHT = 8 # px
	      #
	      # week timings
	      #
	      DAY_HOUR_START = 8    # each day starts at 8:00 AM
	      DAY_HOUR_END   = 20   # each day ends   at 8:00 PM (20:00)
	
	      def cell_time
	        return DEFAULT_CELL_TIME
	      end
	
	      def row_height
	        return DEFAULT_ROW_HEIGHT
	      end
      end

    end

  end
  
end
