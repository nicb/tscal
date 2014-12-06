#
# $Id: lesson_helper.rb 217 2010-02-20 07:00:37Z nicb $
#

require 'string'
require File.dirname(__FILE__) + '/string_helper'

module Test

  module Utilities

    module LessonHelper

      include Test::Utilities::StringHelper

      #
      # make sure that the date doesn't fall on blacklisted dates, so pick a
      # definite safe date
      #
      DEFAULT_START_DATE = Time.zone.local(2009,11,9).monday + 9.hours
      DEFAULT_END_DATE = DEFAULT_START_DATE.since(6.days + 11.hours)

      def create_many_lessons(num, lessons_per_at, start_date = DEFAULT_START_DATE, end_date = DEFAULT_END_DATE,
                              lesson_args = {})
        lesson_args = create_lesson_args(start_date, '60') if lesson_args.empty?
		    at_num = (num.to_f / lessons_per_at.to_f).floor
		    ats = create_many_activated_topics(at_num)
		    ats.each do
		      |at|
		      lessons = ::Lesson.generate_lesson_list(at, start_date, lesson_args)
		      lessons.each { |l| assert l.save; assert l.valid? }
		    end
		    assert result = ::Lesson.all(:conditions => ['start_date >= ? and end_date < ?', start_date, end_date])
		    assert result.size >= num, "#{result.size} < #{num}"
		    return result
		  end
		
		  def create_many_activated_topics(num)
		    result = []
		    0.upto(num-1) do
		      while true
		        name = random_string(5, 50)
		        acro = name.create_acronym
		        its_there_already = Topic.find_by_acronym(acro)
		        break unless its_there_already # select another one if this is already taken
		      end
		      assert t = Topic.create(:name => name, :acronym => acro, :level => 1, :color => '#00FF00')
		      assert t.valid?, "Topic.create(:name => #{name}, :acronym => #{acro}, :level => 1, :color => '#00FF00') failed: #{t.errors.full_messages.join(', ')}"
          assert teacher = users(:nicb)
          assert teacher.id
		      assert at = ActivatedTopic.create(:topic => t, :teacher_id => teacher.id,
		                                        :credits => 2, :duration => 6,
		                                        :semester_start => 1,
		                                        :delivery_type => 'TF')
		      assert at.valid?
		      result << at
		    end
		    return result
		  end

      def create_lesson_args(sd, dur)
        result = {}
        assert sd_hash = { 'dur' => dur, 'start_hour' => sd.hour, 'start_minute' => sd.min }
			  ActiveSupport::TimeWithZone::WDAY_MAP.keys.each do
			    |day|
			    assert result.update(day => sd_hash)
			  end
        return result
      end

    end

  end

end
