#
# $Id: empty.rb 201 2010-01-04 04:32:03Z nicb $
#

module Calendar

  module Event

		class Empty 
      include BaseMethods
      include Calendar::Display::Render
      has_renderer :template_path => 'calendar/event'

      def initialize(sd, ed)
        initialize_base(sd, ed)
      end

      def div_name
        return start_date.today? ? 'cell_empty_today' : 'cell_empty'
      end

      alias_method :height, :height_without_borders

	  end

  end

end
