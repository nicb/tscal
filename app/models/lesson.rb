#
# $Id: lesson.rb 298 2012-11-03 14:34:29Z nicb $
#
require 'fixnum'

class Lesson < ActiveRecord::Base

	attr_accessor :temp_clone_id

  class InvalidFilter < ArgumentError
  end

  include Calendarable
  include Calendar::Display::Render
  include Calendar::Event::InstanceMethods
  has_renderer :template_path => 'calendar/event'
  
  attr_accessor :warnings_cache
  
  belongs_to :activated_topic
	belongs_to :place
  has_many   :lesson_conflicts, :foreign_key => :left_lesson_id

  validates_presence_of   :start_date, :end_date, :activated_topic_id

  #
  #
  #
  class BadDateHash < ActiveRecord::ActiveRecordError
  end
  
  def teacher
    return activated_topic.teacher
  end

  def topic
    return activated_topic.topic
  end

  #
  # ==(other) has to work a bit differently from its super, because we may
  # need to compare two instances that may be new_record?
  #
  def ==(other)
    #
    # if other is not the same class, return false
    #
    return false unless other.is_a?(self.class)
    #
    # if we're both persistent, the super ==(other) applies
    #
    return super(other) unless self.new_record? || other.new_record?
    #
    # otherwise, we compare attribute by attribute
    #
    result = true
    attributes.each do
      |k, v|
      if v != other.attributes[k]
        result = false
        break
      end
    end
    return result
  end

  class << self

    def create(args = {})
      obj = super(args)
      obj.save_conflicts
      return obj
    end

    def prepare_data_set(sd, ed, filter = nil)
      #
      # TODO: perhaps this query can be optimized: it performs 6 queries to
      # make sure that the hours fall within a given time frame, but maybe
      # this could be done more efficiently
      #
      result = []
      curs = Time.zone.local(sd.year, sd.month, sd.day, Calendar::Display::Week::Methods::DAY_HOUR_START, 0)
      cure = Time.zone.local(sd.year, sd.month, sd.day, Calendar::Display::Week::Methods::DAY_HOUR_END, 0)
      while curs < ed
        temp = filtered(curs, cure, filter).compact.uniq
        result << temp
        curs += 1.day
        cure += 1.day
      end
      return result
    end
    
    def filtered(tstart, tend, filter = nil)
      result = nil
      find_options = manage_filter(filter, tstart, tend)
      find_options.update(:order => 'start_date, end_date')
      return all(find_options)
    end

		#
		# <tt>generate_lesson_list</tt>
		# generates a list of lessons to be proposed to the teacher. It takes
		# the following arguments
		#
		# * the <tt>ActivatedTopic</tt> object which is related to it
		# * the starting day
		# * a hash which carries all the information required to build the list;
		#   here is an example hash for the third argument:
		#   { 'Martedì' => { 'dur' => 120, 'start_hour' => 10, 'start_minute' => 00 },
		#     'Venerdì' => { 'dur' => 300, 'start_hour' => 15, 'start_minute' => 30 }}
		#
    def generate_lesson_list(at, start_day, iwdays)
      dur = at.duration * 60 # at.duration must be transformed in minutes
      curday = start_day
      lessons = []
      while dur > 0
				curday = curday.next_available_day(iwdays.keys)
				raise(BadDateHash, "iwdays hash is malformed (#{iwdays.inspect}) - expects #{curday.iwday}") unless iwdays && iwdays.has_key?(curday.iwday) && iwdays[curday.iwday].has_key?('dur')
				curdur = iwdays[curday.iwday]['dur'].to_i
				curdur = curdur < dur ? curdur : dur
				curplace = nil
				curplace = iwdays[curday.iwday]['place_id'].to_i unless iwdays[curday.iwday]['place_id'].to_i == 0
				thisdate = Time.zone.local(curday.year,curday.month,curday.day,iwdays[curday.iwday]['start_hour'].to_i, iwdays[curday.iwday]['start_minute'].to_i)
				lessons << Lesson.new(:activated_topic => at, :start_date => thisdate, :duration => curdur, :place_id => curplace)
				dur -= curdur
				curday += 1.day #we don't want to trip on the same day
      end
      return lessons
   end

    def manage_filter(filter, date_start, date_end)
      result = {}
      date_condition_string = "(lessons.start_date >= ? and lessons.end_date <= ?)"
	    conditions = [ date_start, date_end ]
      if filter && filter != 'Mostra_Tutto'
        (kname, id) = filter.split('.')
        begin
	        klass = kname.constantize
	        obj = klass.find(id)
	        if obj
            conds = obj.generate_conditions
            if conds.blank?
              conditions.unshift(date_condition_string)
              result.update(:conditions => conditions)
            else
	            conds = '(' + conds + ')'
	            condition_string = date_condition_string + (' and ' + conds)
	            conditions.unshift(condition_string)
	            result.update(obj.generate_query_hash(conditions))
            end
	        else
	          raise(InvalidFilter, "Invalid Filter: \"#{filter.to_s}\" (#{$!})", caller)
	        end
        rescue
	        raise(InvalidFilter, "Invalid Filter: \"#{filter.to_s}\" (#{$!})", caller)
        end
      else
        conditions.unshift(date_condition_string)
        result.update(:conditions => conditions)
      end
      return result
    end

  end

  #
  # destroy has to take care of all LessonConflict records explicitely because
  # we don't know whether we are a left_lesson or a right_lesson
  #
  def destroy
    super
    destroy_conflicts
  end

  #
  # +verify_compatibility+ checks whether this lesson is conflicting with
  # anything else. Returns +true+ when lesson is compatible (i.e. there are no
  # conflicts, +false+ otherwise.
  #
  def verify_compatibility(force = false)
    return conflicts(force).empty? ? true : false
  end

  #
  # +conflicts?+ is the opposite of verify_compatibility (+true+ when there
  # are conflicts, +false+ otherwise).
  #
  def conflicts?(force = false)
    return !verify_compatibility(force)
  end

public

  def same_course_starting_year?(other)
    return activated_topic.course_starting_year == other.activated_topic.course_starting_year
  end

  def conflicts(force = false)
    return new_record? || force ? uncached_conflicts : cached_conflicts
  end

  def uncached_conflicts
		result    = []
    #
    # NOTE: this is the optimized version of the uncached_conflicts call. When events
    # are going to be introduced care should be taken to check against all
    # events
    #
    lid = case
          when self.id : self.id
          when temp_clone_id : temp_clone_id
          else nil
          end
    lid_string = lid ? " and (lessons.id != #{lid})" : ''
    csy_string = activated_topic.course_starting_years.map { |csy| "(course_topic_relations.course_starting_year_id = #{csy.id})" }.join(' or ')
		#
		# if no current year is reported we are not conflicting at all
		#
		unless csy_string.blank?
      csy_string = '(' + csy_string + ') and '
      result   = self.class.find(:all, :select => 'lessons.*', :from => 'activated_topics,course_topic_relations,lessons',
                            :conditions => ["(#{csy_string}course_topic_relations.activated_topic_id = activated_topics.id and lessons.activated_topic_id = activated_topics.id #{lid_string}) and ((lessons.start_date <= ? and lessons.end_date > ?) or (lessons.start_date < ? and lessons.end_date >= ?) or (lessons.start_date >= ? and lessons.end_date <= ?) or (lessons.start_date <= ?  and lessons.end_date >= ?))",
                                            start_date, start_date,
                                            end_date, end_date,
                                            start_date, end_date,
                                            start_date, end_date ],
                                            :order => 'lessons.start_date, lessons.end_date, lessons.created_at, lessons.updated_at').uniq
		end
    return result
  end

  def destroy_conflicts
    lcs = LessonConflict.all(:conditions => ["left_lesson_id = ? or right_lesson_id = ?", id, id])
    lcs.each { |lc| lc.destroy }
  end

  def save_conflicts
    destroy_conflicts
    result = uncached_conflicts
    result.each { |l| lesson_conflicts.create(:right_lesson => l) }
  end

  def cached_conflicts
    result = Lesson.all(:select => 'lessons.*', :from => 'lessons,lesson_conflicts',
                        :conditions => ["(lesson_conflicts.left_lesson_id = ? and lesson_conflicts.right_lesson_id = lessons.id) or (lesson_conflicts.right_lesson_id = ? and lesson_conflicts.left_lesson_id = lessons.id)", id, id],
                        :order => 'lessons.start_date, lessons.end_date')
    return result
  end

  def clone
    result = super
    result.temp_clone_id = id
    return result
  end

  def cloned?
    return !id && !temp_clone_id.nil?
  end

  def cloned_from?(other)
    return cloned? && temp_clone_id == other.id
  end

  def clone_attributes(reader_method = :read_attributes, attrs = {})
    result = cloned? ? attributes.dup : super(reader_method, attrs)
    result.delete(self.class.primary_key)
    %w(created_at updated_at).each { |k| result.delete(k) }
    return result
  end

  def update_cloner!
    if cloned?
      cloner_obj = self.class.find(temp_clone_id)
      attrs = clone_attributes
      cloner_obj.update_attributes!(attrs)
    end
  end

  #
  # display methods
  #
    
  def name
    display_tooltip
  end

  def year
    return activated_topic.year
  end

	def topic_display
		activated_topic.topic.display
	end

	def topic_display_tooltip
		activated_topic.topic.display_tooltip
	end
  
	def course_color
    result = 'gray'
    #
    # FIXME: this will need to be changed with stripped colors for lessons
    # that are shared among courses
    #
    result = activated_topic.course_starting_years[0].color if activated_topic && !activated_topic.course_starting_years.empty? && verify_compatibility
    return result
	end

	def topic_color
		activated_topic.topic.color
	end

	def background_color
    result = 'black'
    if verify_compatibility
		  c = Color::RGB.from_html(topic_color)
		  mc = Color::Palette::MonoContrast.new(c)
		  result = mc.foreground[5].html
    end
    return result
	end

	def title_color
    result = 'gray'
    if verify_compatibility
		  c = Color::RGB.from_html(topic_color)
		  mc = Color::Palette::MonoContrast.new(c)
		  result = mc.background[3].html
    end
    return result
	end

	def course_display
    return course_display_common(:display)
	end

	def course_display_tooltip
    return course_display_common(:display_tooltip)
	end

private

  def course_display_common(meth)
    result = []
    activated_topic.course_starting_years.each do
      |csy|
      result << csy.course.send(meth) + ' (' + csy.anno + ')'
    end
    return result.join('/')
  end

public

  def full_info_tooltip
    return topic_display_tooltip + ', ' + course_display_tooltip +
      ' (' + time + '), Docente: ' +
      activated_topic.teacher.full_name + ', Prima Lezione: ' +
      activated_topic.lessons.first.start_date.to_s + ', Ultima Lezione: ' +
      activated_topic.lessons.last.start_date.to_s
  end

	def time
    sd = start_date.dup
    ed = end_date.dup
 		start = sd.hour.to_ss + ':' + sd.min.to_ss
 		finish = ed.hour.to_ss + ':' + ed.min.to_ss
 		return start + ' - ' + finish
	end

	def div_class
    return verify_compatibility ? 'valid_lesson' : 'conflicting_lesson'
	end

  def warnings
    result = ''
    if conflicts? && (cs = conflicts)
      csstrings = cs.map { |l| "la lezione di #{l.activated_topic.topic.display_tooltip} di #{l.activated_topic.teacher.full_name} (#{l.time})" }
      result = "Questa lezione è in conflitto con " + csstrings.join(', ')
    end
    return result
  end

  #
  # should bypass the start_date attribute writing
  #

  def raw_start_date=(d)
    common_date_attribute_writer(:start_date, d)
  end

  def end_date=(d)
    common_date_attribute_writer(:end_date, d)
  end

private

  def common_date_attribute_writer(method, date)
    write_attribute(method, date)
    save_conflicts unless self.new_record?
  end

public
  #
  # required to be grokked by calendarable
  #
  def start_date
    return cast_date_attribute(:start_date)
  end

  def end_date
    return cast_date_attribute(:end_date)
  end

  #
  # required by jquery version of calendar
  #

  def start_date_ietf
    return read_attribute(:start_date)
  end

  def end_date_ietf
    return read_attribute(:end_date)
  end
  
  # 
  #required to get the conflicts right
  #
  
  def start_date=(d)
		dur = self.duration
    write_attribute(:end_date, d+dur.minutes) if self.end_date_locked?
	  write_attribute_with_conflict_check(:start_date, d)
  end
  
  
  def dur=(d)
  	write_attribute_with_conflict_check(:dur, d)
  end

private

  def write_attribute_with_conflict_check(attrib,val)
 	  write_attribute(attrib, val)
   	save_conflicts if self.activated_topic && !self.new_record?
  	val
  end

  def cast_date_attribute(attribute)
    t = read_attribute(attribute)
    return Time.zone.parse(t.to_s)
  end

private
  
  def initialize(parms={})
    super(handle_duration_arg(parms))
  end

public

  def inspect
    return super.sub(/>/, ", temp_clone_id: #{@temp_clone_id.to_s}>")
  end

  #
  # raw_start_date=(d) is required by the Calendarable module
  #

  def raw_start_date=(d)
    return write_attribute(:start_date, d)
  end

  #
  # hash returns a clone lesson in a hash that is digestible to activated topic's
  # creation methods
  #

  def to_hash_clone
    c = clone
    return HashWithIndifferentAccess.new(:id => c.id, :temp_clone_id => c.temp_clone_id,
                                         :duration => c.duration,
                                         :start_date => { 'start_date(1i)' => c.start_date.year.to_s,
                                         'start_date(2i)' => c.start_date.month.to_s,
                                         'start_date(3i)' => c.start_date.day.to_s,
                                         'hour'           => c.start_date.hour.to_s,
                                         'minute'         => c.start_date.min.to_s, })
  end

end
