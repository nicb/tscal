#
# $Id: display.rb 215 2010-02-20 04:56:54Z nicb $
#

require 'datetime'

module Calendar

  module Display

    module Week

		  class Display < Matrix

        include Calendar::Display::Render
        has_renderer :template_path => 'calendar/week'

        attr_reader :start_date, :end_date, :step
		    
		    def initialize(d = nil)
          d = Time.zone.now unless d
		      @start_date = d.monday # round the sunday to the incoming week
          @end_date = @start_date + 5.days
		      @step = 1.day
          initialize_days
		    end
		
        private :start_date, :end_date

		    alias_method :days, :columns

        include Calendar::Display::Week::Methods

        def week_start
          return start_date + DAY_HOUR_START.hours
        end

        def week_end
          return end_date + DAY_HOUR_END.hours
        end

        class DataSetMismatch < ArgumentError; end
        class DataSetSizeMismatch < DataSetMismatch; end
        class EventDateMismatch < DataSetMismatch; end
        #
        # insert_data_set allows to add calendarable objects to this Calendar
        # Display in a seamless way. The data set argument must respect the
        # following requirements:
        # - it must be an array of arrays with the same number of columns of
        #   the Calendar columns
        # - the events in each column must be time-ordered in start_date,
        #   end_date order
        # - the events must fall in the day span allowed for display
        #
        def add_data_set(data_set)
          raise(DataSetSizeMismatch, "The data set size is not compatible with this calendar display (size: #{data_set.size} != #{columns.size})") unless data_set.size == columns.size
          data_set.each_index do
            |i|
            raise(DataSetMismatch, "An inner object of the data set is not an Array as expected (it is a #{data_set[i].class.name} instead)") unless data_set[i].is_a?(Array)
            data_set[i].each do
              |e|
              dsd = e.start_date
              ded = e.end_date
              csd = columns[i].day_start
              ced = columns[i].day_end
              raise(EventDateMismatch, "The event #{e.inspect} cannot be added to this calendar display (d.start_date #{dsd} OR d.end_date #{ded} fall outside the boundaries of the day (#{csd}, #{ced})") if dsd < csd || dsd > ced || ded < csd || ded > ced
              columns[i] << e
            end
          end
        end

        #
        # row_header_special(day) returns 'first' if the day is the first day,
        # or 'last' if the day is the last day of the week or else nothing
        # (required by css in the display)
        #

        def row_header_special(day)
          result = ''
          result = 'first' if day.object_id == days.first.object_id
          result = 'last'  if day.object_id == days.last.object_id
          return result
        end

      protected

        def prepare_rendering
          result = []
          rh = RowHeader.new(week_start)
          result << rh.renderer
          days.each do
            |d|
            result << d.renderer
          end
          return result
        end

      private

		    def initialize_days
          @columns = []
          sd = start_date
          cols = ((end_date - sd) / self.step).to_i + 1 # 6 days from Mon to Sat included
          0.upto(cols-1) do
            @columns << Day.new(sd)
            sd += self.step
          end
        end

		  end  

    end

  end
  
end
