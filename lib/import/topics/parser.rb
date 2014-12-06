#
# $Id: parser.rb 290 2012-07-31 01:45:43Z nicb $
#

module Import

	module Topics
	
	  module Parser
	
	    def parse(analyzed_data)
	      tt = analyzed_data[:activated_topic].delete(:teaching_typology)
		    teacher = find_or_create_teacher(analyzed_data[:teacher])
		    topic_args = create_topic_args(analyzed_data[:topic][:name])
		    topic = find_or_create(::Topic, 'name_and_level', topic_args, analyzed_data[:topic][:name])
		    at_args = create_at_args(analyzed_data[:activated_topic], teacher, topic)
		    at = find_or_create(::ActivatedTopic, 'topic_id_and_teacher_id', at_args, topic.name)
        cas = get_course_acronyms(analyzed_data)
        cas.each do
          |ca|
		      course = find_or_create(::Course, 'acronym', ca, ca)
	        csy = retrieve_csy(at, course)
          cy = (CourseStartingYear::CURRENT_AA - csy.starting_year) + 1
	        at.link_to_course_starting_years([ { csy.id.to_s => {'status' => '1', 'teaching_typology' => tt, 'mandatory_flag' => true, 'course_year' => cy }} ]) if cy <= 3
        end
	    end
	
	  private
	
      def get_course_acronyms(analyzed_data)
        return analyzed_data[:course][:acronym].split('/')
      end

	    def create_teacher_args(teacher)
	      name_re = Regexp.new(/[\s']+/)
	      result = { :teacher_typology => teacher[:teacher_typology] }
	      (first_name, last_name) = teacher[:full_name].split(/\s+/, 2)
	      result.update(:last_name => last_name, :first_name => first_name)
	      passwd = teacher[:full_name].gsub(name_re, '').downcase
	      login = first_name.gsub(name_re,'').downcase + '.' + last_name.gsub(name_re, '').downcase
	      other_args =
	      {
	        :login => login,
	        :email => 'non_disponibile@conservatoriopollini.it',
	        :password => passwd,
	        :password_confirmation => passwd,
	      }
	      result.update(other_args)
	      return result
	    end
	
	    DEFAULT_COLOR = '#f00ff0'
	
	    def create_topic_args(topic)
	      t = topic.strip.sub(/\s*\(.*\)$/, '') # remove trailing parenthesized stuff
	      name_re = /\s*([0-9]+)\s*$/
	      level_re = /^.*#{name_re}/
	      level = ''
	      if t =~ name_re
	        name = t.sub(name_re, '').strip
	        level = t.sub(level_re, '\1')
	      else
	        name = t.strip
	      end
	      level = level.blank? ? nil : level
	      return { :name => name.capitalize_all.strip, :acronym => name.create_acronym, :level => level, :color => DEFAULT_COLOR }
	    end
	
	    def find_or_create(klass, method, args, error_tag)
	      m = 'find_or_create_by_' + method
	      result = klass.send(m, args)
debugger unless result.respond_to?(:errors)
	      raise(ActiveRecord::RecordNotFound, "#{klass.name} \"#{error_tag}\" could not be found or created (#{result.errors.full_messages.join(', ')})") unless result && result.valid?
	      return result
	    end
	
	    #
	    # this must be specialized because password_confirmation doesn't pass find_or_create
	    #
	    def find_or_create_teacher(t)
	      teacher_args = create_teacher_args(t)
	      teacher = Teacher.find_by_last_name_and_first_name(teacher_args[:last_name], teacher_args[:first_name])
	      unless teacher && !teacher.id.blank?
	        teacher = Teacher.create(teacher_args)
debugger unless teacher.respond_to?(:errors)
	        raise(ActiveRecord::RecordNotFound, "Teacher \"#{t[:full_name]}\" could not be found or created (#{teacher.errors.full_messages.join(', ')})") unless teacher && !teacher.id.blank?
        else
          teacher.update_attributes!(:teacher_typology => t[:teacher_typology], :password_confirmation => 'dummy')
	      end
	      return teacher
	    end
	
	    def create_at_args(at, teach, top)
	      result = at
	      result.update(:teacher_id => teach.id, :topic_id => top.id)
	      return result
	    end

      def retrieve_csy(at, crs)
	      result = find_or_create_course_starting_year(crs, at[:semester_start])
        return result
      end
	
	    def find_or_create_course_starting_year(crs, sem_start)
	      our_AA = 2009
	      sy = our_AA - ((sem_start - 1) / 2) # two semesters per year
	      csy_args = { :course_id => crs.id, :starting_year => sy, :color => DEFAULT_COLOR }
	      csy = find_or_create(CourseStartingYear, 'course_id_and_starting_year', csy_args, crs.name + ' ' + sy.to_s)
	      return csy
	    end
	
	  end
	
	end

end
