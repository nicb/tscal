#
# $Id: group.rb 201 2010-01-04 04:32:03Z nicb $
#

#require 'datetime'

module Calendar

  module Event

	  #
	  # Calendar::Event::Group is a class that allows nesting
    # of other events to include multiple events in a single column.
	  #
	  class Group

      attr_reader :columns, :column_width

      include BaseMethods
      include Calendar::Display::Render
      has_renderer :template_path => 'calendar/event'

	    def initialize
        @columns = [] # @columns is an array of Event::Column(s)
        @column_width = nil
	    end
	
      def <<(ev)
        columns << Column.new
        columns.last << ev
        initialize_base(ev.start_date, ev.end_date) if columns.size == 1
        self.end_date = ev.end_date if ev.end_date > self.end_date
      end

      def size
        return columns.size
      end

      def column_width # percentage as needed by css attribute 'width'
        @column_width = @column_width ? @column_width : (100.0/size.to_f)
        return @column_width
      end

      alias_method :height, :height_without_borders

    protected

      #
      # the rendering object is hash which has a field for the group itself and
      # then an array of events
      #
      def prepare_rendering
        result = { :group => self, :columns => [] }
        columns.each do
          |cols|
          result[:columns] << cols._prepare_rendering(start_date, end_date)
        end
        return result
      end

	  end

  end

end
