#
# $Id: column.rb 201 2010-01-04 04:32:03Z nicb $
#
module Calendar

  module Event

	  #
    # Event::Column piles up a list of events ordered by start_date, end_date
    # - it keeps track of the total time
    # - when rendering, it fills empty time with Event::Empty objects
	  # - it will *not* keep track of overlapping events. In fact, it will raise
    #    an exception when encountering an overlapping event
    # - it will accept only time-ordered events: anything else will raise
    #   an exception
    #
	  class Column < Column::Base

      include BaseMethods

      class OverlappingEvent < ArgumentError
      end

      class NonTimeOrderedEvent < ArgumentError
      end

      def <<(ev)
        return super(ev) if blank?
        raise(NonTimeOrderedEvent, "Event is not ordered in time for this column (ev.start_date(#{ev.start_date}) < last.start_date(#{last.start_date}))") if ev.start_date < last.start_date
        raise(OverlappingEvent, "Event is overlapping with last event in column (ev.start_date(#{ev.start_date}) < last.end_date(#{last.end_date})) - consider using an Event::Group object") if ev.start_date < last.end_date
        return super(ev)
      end

      def start_date
        return date_wrapper { first.start_date }
      end

      def end_date
        return date_wrapper { last.end_date }
      end
	
	    def _prepare_rendering(ds, de)
        result = { :column => self, :events => [] }
	      curt = ds
	      each do
	        |e|
	        diff = e.start_date - curt
	        result[:events] << Empty.new(curt, e.start_date).renderer unless diff <= 0
	        result[:events] << e.renderer
          curt = e.end_date
	      end
        result[:events] << Empty.new(curt, de).renderer if curt < de
	      return result
	    end

    protected

      def date_wrapper
        result = nil
        result = yield unless blank?
        return result
      end
	
	  end

  end

end
