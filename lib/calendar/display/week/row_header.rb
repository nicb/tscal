#
# $Id: row_header.rb 201 2010-01-04 04:32:03Z nicb $
#

module Calendar
  
  module Display

    module Week

      class RowHeaderEvent 

        attr_reader :time_display

        include Event::BaseMethods
        include Calendar::Display::Render
        has_renderer :template_path => 'calendar/week'

        def initialize(sd, ed)
          initialize_base(sd, ed)
          @time_display = self.start_date.strftime('%H:%M')
        end

        def height
          return (row_height << 1) - 2
        end

      end

		  class RowHeader < DayBase

        include Calendar::Display::Render
        has_renderer :template_path => 'calendar/week'

        def initialize(day)
          super(day)
          initialize_hours
        end

      private

        def initialize_hours
          curt = self.day_start
          while curt < self.day_end
            ed = curt + (cell_time * DEFAULT_ROW_SPAN).minutes
            self.<< RowHeaderEvent.new(curt, ed)
            curt = ed
          end
        end

        def prepare_rendering
          return map { |rhe| RowHeaderEvent::RowHeaderEventRenderer.new(rhe) }
        end
		
		  end

    end

  end

end
