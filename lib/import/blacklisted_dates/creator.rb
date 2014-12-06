#
# $Id: creator.rb 262 2010-08-31 21:31:28Z nicb $
#

module Import

  module BlacklistedDates

    class Creator
      attr_reader :date_list

      def initialize(dl)
        @date_list = dl
      end

      def create
        self.date_list.each do
          |di|
          di.to_a.each do
            |d|
	          dt = DateTime.civil(d.year, d.month, d.day, 2)
	          bd = ::BlacklistedDate.create(:blacklisted => dt, :description => d.description)
	          raise(ActiveRecord::RecordInvalid) unless bd.valid?
	          puts("#{bd.blacklisted.to_s} => #{bd.description}")
          end
        end
      end

    end

  end

end
