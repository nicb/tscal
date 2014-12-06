#
# $Id: date_interval.rb 262 2010-08-31 21:31:28Z nicb $
#

module Import
  
  module BlacklistedDates

    class DescriptiveDate < Date
      attr_accessor :description

      class << self

	      def new1(jd, desc)
	        instance = super(jd)
	        instance.description = desc
	        return instance
	      end

      end

      def to_s
        return strftime("%d/%m/%Y => #{self.description}")
      end

    end

    class DateInterval

      attr_reader :start_date, :end_date, :description

      def initialize(sd, ed, desc)
        @start_date = parse_date(sd)
        @end_date = parse_date(ed)
        @description = desc
      end

      def to_a
        result = []
        sd = self.start_date
        diff = (self.end_date.jd - sd.jd)
        0.upto(diff) do
          |n|
          result << DescriptiveDate.new1(sd.jd + n, self.description)
        end
        return result
      end

    private

      def parse_date(d)
        (day, month, year) = d.split(/\//)
        return Date.civil(year.to_i, month.to_i, day.to_i)
      end

    end

  end

end
