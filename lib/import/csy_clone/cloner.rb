#
# $Id: cloner.rb 263 2010-09-02 19:23:53Z nicb $
#

module Import

  module CsyClone

    class Cloner
      attr_reader :dest_year, :src_year, :course

      def initialize(dy, c)
        @dest_year = dy.to_i
        @src_year  = self.dest_year - 1
        @course = c
      end

      def clone
        src_csy = CourseStartingYear.find_by_course_id_and_starting_year(self.course.id, self.src_year)
        dest_csy = CourseStartingYear.find_by_course_id_and_starting_year(self.course.id, self.dest_year)
        if src_csy.valid? && dest_csy.valid?
          src_csy.activated_topics.each do
            |sat|
            puts("csy #{dest_csy.starting_year}: activating topic #{sat.topic.name} with teacher => #{sat.teacher.full_name}")
            dat = dest_csy.activated_topics.create(:topic => sat.topic, :teacher => sat.teacher,
                                             :duration => sat.duration, :semester_start => sat.semester_start,
                                             :credits => sat.credits)
            raise(ActiveRecord::RecordInvalid, "failed to activate  topic #{sat.topic.name} with teacher => #{sat.teacher.full_name}: #{dat.errors.full_messages.join(', ')}") unless dat.valid?
          end
        end
      end

    end

    class MultiCloner
      attr_reader :years, :course

      def initialize(ys, c)
        @years = create_year_sequence(ys)
        @course = c
      end

      def clone
        self.years.each do
          |y|
          cloner = Cloner.new(y, self.course)
          cloner.clone
        end
      end

    private

      def create_year_sequence(ys)
        result = []
        (ystart, yend) = ys.split('-')
        if yend
          result = ystart.to_i.upto(yend.to_i).sort.reverse
        else
          result = [ystart]
        end
        return result
      end

    end

  end

end
