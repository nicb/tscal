#
# $Id: random.rb 298 2012-11-03 14:34:29Z nicb $
#

require File.expand_path(File.join(File.dirname(__FILE__), 'string_helper'))

module Test

	module Utilities

		module Random

		  def random_topic
		    return random_something { |n, a| Topic.create(:name => n, :acronym => a, :color => '#ff00ff', :level => 1) }
		  end
		
		  def random_course
		    return random_something { |n, a| Course.create(:name => n, :acronym => a, :duration => 3) }
		  end
		
		  def random_course_starting_year(sy = CourseStartingYear::CURRENT_AA - 2, c = nil)
				c = random_course unless c
		    result = random_something do
		      |n, a|
		      CourseStartingYear.create(:course => c, :starting_year => sy, :color => '#00ff00')
		    end
		    return result
		  end
		
		  #
		  # random_course_starting_years returns a hash suitable to test the
		  # link_to_course_starting_years method; out of these, half of them
			# should statistically be current, while the other half should not.
			# However, for the purpose of testing we should make sure that at least
			# *one* csy is current.
		  #
		  def random_course_starting_years(nominal_num = 20)
		    num = (rand * nominal_num).round
		    csys = []
		    0.upto(num-1) { csys << random_course_starting_year }
		    result = {}
		    csys.each_with_index do
		      |csy, idx|
		      tt = CourseTopicRelation::TEACHING_TYPOLOGIES[(rand * CourseTopicRelation::TEACHING_TYPOLOGIES.size.to_f).round - 1]
		      mf = rand.round == 1 ? 'Obbligatorio' : 'A Scelta'
					force_current = idx == 0 ? true : false
					csy.update_attributes(:starting_year => CourseStartingYear::CURRENT_AA - ((rand() * 2.0).round)) if force_current
		      cy = select_current_year(csy, force_current)
		      csy_h = { 'teaching_typology' => tt[1], 'mandatory_flag' => mf, 'course_year' => cy }
		      csy_h.update('status' => '1') if force_current || rand.round == 1
		      result.update(csy.id.to_s => csy_h)
		    end
		    return result
		  end

			include Test::Utilities::StringHelper
		
		  def random_something
		    begin
		      name = random_string
		      acro = random_string(2, 3)
		      assert result = yield(name, acro)
		    end while result.invalid? && (result.errors.on(:name) || result.errors.on(:acronym))
		    assert result.valid?, "#{result.class.name}(:name => #{name}) invalid (#{result.errors.full_messages.join(', ')})"
		    return result
		  end

		private

			def select_current_year(csy, force_current = false)
				cy = nil
				should_be_current = (force_current || rand() > 0.5) ? true : false
				if should_be_current && csy.starting_year >= (CourseStartingYear::CURRENT_AA - 2)
					cy = CourseStartingYear::CURRENT_AA - csy.starting_year + 1
				else
					cy = (rand() * 2.0).round + 1
				end
				cy
			end

		end

		module RandomEnvironment

			include Random

			#
			# +DEFAULT_ENVIRONMENT_OPTIONS+ is the set of fallback options used by
			# +random_environment+ if no options are supplied
			#
			DEFAULT_ENVIRONMENT_OPTIONS =
			{
					'num_courses' => 3,
					'year_start'  => CourseStartingYear::CURRENT_AA - 5,
					'year_end'    => CourseStartingYear::CURRENT_AA,
					'num_topics'  => 5,
					'num_lessons' => 5,
					'stale_with_future_lessons' => false,
			}

			class UnknownEnvironmentOption < RuntimeError; end

			#
			# <tt>random_environment(teacher, env_options = {})</tt>:
			# * clears the environment
			# * generates the prescribed number of courses
			# * generates the prescribed number of topics
			# * generates the number of course_starting_years to fill all courses
			#   for every year
			# * generates the number of activated topics to fill all topics for
			#   every year (num_topics * num_course_starting_years)
			# * generates the number or CourseTopicRelation object to link each
			#   activated topic to each course
			# * generate the prescribed number of lessons for each activated topic
			# * if the 'stale_with_future_lessons' is set to true, it also generates
			#   a set of lessons which start in the past and end in the future
			#
			def random_environment(teacher, env_options = {})
				assert lesson_iwdays =
				{
					'Martedì' => { 'dur' => 60, 'start_hour' => 10, 'start_minute' => 0 },
					'Venerdì' => { 'dur' => 60, 'start_hour' => 15, 'start_minute' => 30 },
				}
				assert num_of_ctr_links = 0
				options = DEFAULT_ENVIRONMENT_OPTIONS.dup
				env_options.stringify_keys!
				env_options.each do
					|k, v|
					raise(UnknownEnvironmentOption, "tried to set unknown environment option \"#{k}\"") unless options.has_key?(k)
					options.update(k => v)
				end
				clear_environment
				operations = { 'course' => options['num_courses'], 'topic'  => options['num_topics'], }
				operations.each do
					|k, v|
					assert meth = "random_#{k}"
					1.upto(v) { assert obj = send(meth) }
					assert objclass = k.singularize.capitalize.constantize
					assert_equal v, objclass.count
				end
				assert ys = options['year_start']
				assert ye = options['year_end']
				assert yrange = ye - ys + 1
				Course.all.each { |c| ys.upto(ye) { |year| assert csy = random_course_starting_year(year, c) } }
				Topic.all.each do
					|t|
					assert credits = (rand()*7).round + 1
					assert dur = (rand()*16).round + 16
					assert sem = (rand()).round + 1
					assert at = ActivatedTopic.create(:topic => t, :teacher => teacher, :credits => credits, :duration => dur, :semester_start => sem)
					assert at.valid?, at.errors.full_messages.join(', ') 
				end
				Course.all.each do
					|course|
					course.course_starting_years(true).each do
						|csy|
						ActivatedTopic.all.each do
							|at|
							link_it = rand().round == 1 ? true : false
							if link_it
								assert cy = (rand()*2).round + 1
								assert ctr = at.course_topic_relations.create(:course_starting_year => csy, :course_year => cy)
								assert ctr.valid?
								assert num_of_ctr_links += 1
								start_date = Time.zone.local(csy.starting_year + ctr.course_year - 1, 3, 10, 2, 0, 0)
								start_date = Time.zone.now - 15.days if !ctr.is_current? && options['stale_with_future_lessons']
								lessons = Lesson.generate_lesson_list(at, start_date, lesson_iwdays)
								lessons.each { |l| l.save! }
							end
						end
					end
				end
				num_of_ctr_links
			end

			def clear_environment
				records = [Course, Topic, ActivatedTopic, CourseStartingYear, CourseTopicRelation]
				records.each { |r| r.delete_all }
			end

		end
	end

end
