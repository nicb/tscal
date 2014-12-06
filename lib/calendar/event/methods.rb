#
# $Id: methods.rb 201 2010-01-04 04:32:03Z nicb $
#

module Calendar

  #
  # Event objects must have:
  # - a start_date variable (ActiveSupport::TimeWithZone)
  # - an  end_date variable (ActiveSupport::TimeWithZone)
  # - a duration variable (in minutes - Fixnum)
  #
  module Event

    module InstanceMethods

      include Calendar::Display::Week::Methods

      #
      # there are essentially two kind of objects:
      # - objects which have top and bottom borders
      # - objects which have no borders
      #
      # so we fork out two methods, leaving to the object to alias to the
      # proper one
      #
      # we default the height to the "with_borders" method because
      # that is the most common situation
      #
			def height_without_borders
        steps = (duration.to_f / cell_time.to_f).round
				return (steps * row_height)
			end

      def height_with_borders
        return height_without_borders - 2 # 2 px for borders (FIXME: this should be parametrized)
      end

      alias_method :height, :height_with_borders

    end
	
  end

end
