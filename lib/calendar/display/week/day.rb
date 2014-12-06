#
# $Id: day.rb 201 2010-01-04 04:32:03Z nicb $
#

module Calendar
  
  module Display

    module Week

		  class Day < DayBase

        include Calendar::Display::Render
        has_renderer :template_path => 'calendar/week'

        def <<(ev)
          begin
            result = super(ev)
          rescue Event::Column::OverlappingEvent
            if last.class == Event::Group
              result = last << ev
            else
              last_event = pop
              eg = Event::Group.new
              eg << last_event
              eg << ev
              result = super(eg)
            end
          end
          return result
        end

        alias_method :height, :height_without_borders

		  protected
	
        def prepare_rendering
          return _prepare_rendering(day_start, day_end)
        end
		
		  end

    end

  end

end
