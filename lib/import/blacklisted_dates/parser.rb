#
# $Id: parser.rb 262 2010-08-31 21:31:28Z nicb $
#
module Import

  module BlacklistedDates

		class Parser
		
		  attr_reader :filename, :academic_year, :blacklisted_dates
		
		  FILENAME_TEMPLATE = File.dirname(__FILE__) + "/../../../db/import/blacklisted_dates/%s/dates.txt"
		
		  def initialize(aa)
		    @academic_year = aa
		    @filename = sprintf(FILENAME_TEMPLATE, self.academic_year)
		    @blacklisted_dates = []
		  end
		
		  def parse
        result = []
		    File.open(self.filename, 'r') do
		      |fh|
		      while (line = fh.gets)
		        di = parse_line(line)
            result << di if di
		      end
		    end
        return result
		  end
		
		private
		
		  def parse_line(line)
        return parse_code_line(line) unless(line =~ /^$/ || line =~ /^#/)
		  end

      def parse_code_line(line)
        (desc, startdate, enddate) = line.split('|')
        return DateInterval.new(startdate, enddate, desc)
      end
		
		end

  end

end
