#
# $Id: activated_topic.rb 298 2012-11-03 14:34:29Z nicb $
#
require 'time_zone'
require 'array'

class ActivatedTopic < ActiveRecord::Base

  attr_accessor :warnings
  
  belongs_to :topic
  belongs_to :teacher


  belongs_to :prerequisite, :class_name => 'ActivatedTopic'

	has_many :lessons, :dependent => :destroy, :order => 'start_date, end_date'

	class << self

	private
		#
		# <tt>current_year_and_lesson_conditions</tt>: this method prepares the
		# condition query to perform the <tt>currently_active_topics</tt>
		# selection
		#
		def current_year_and_lesson_conditions
			conds = []
			1.upto(3) do
				|y|
				year = CourseStartingYear::CURRENT_AA - y + 1
				conds << "(course_starting_years.starting_year = #{year} AND course_topic_relations.course_year = #{y})"
			end
			res = '(' + conds.join(' OR ') + ')'
  		t = Time.zone.now.to_date.to_param
  		res += " OR (lessons.start_date <= '#{t}' AND lessons.end_date >= '#{t}')"
		end

		def course_order
			'courses.acronym, courses.name, course_starting_years.starting_year desc'
		end

		def topic_order
			'topics.name, topics.level'
		end

	public
		#
		# <tt>currently_active_topics</tt>: this method checks
		# a) whether course years and course starting years are effectively
		#    current
		# b) OR if there are lessons that are currently crossing the +Time.now+
		#    boundary (that is, they are still being performed)
		#
		# This method should now supercedes the
		# <tt>all_current_sorted_by_topic_name</tt> which is now obsoleted and
		# deprecated (and removed, that is)
	  #
	  # <tt>currently_active_topics</tt> accepts a string argument for extra
	  # conditions to be added to the ones already enforced by the call itself
		#
		def currently_active_topics(other_conditions = [])
			final_conditions = current_year_and_lesson_conditions
			unless other_conditions.empty?
				condition_string = final_conditions + (' AND ' + other_conditions.shift) 
				final_conditions = [ condition_string, other_conditions ].compact.flatten
			end
			all(:include => [:course_starting_years, :course_topic_relations, :lessons, :topic, :teacher], :joins => 'LEFT JOIN courses ON course_starting_years.course_id = courses.id', :conditions => final_conditions, :order => topic_order)
		end

	end

  has_many :course_topic_relations, :dependent => :destroy, :uniq => true
  has_many :course_starting_years, :through => :course_topic_relations, :include => [ :course, ], :order => course_order

  validates_presence_of :topic_id, :teacher_id, :duration, :semester_start, :credits

  validates_numericality_of :credits, :semester_start, :duration

	#
	# <tt>courses</tt> returns the list of courses related to this activated topic
	#
	def courses
		connection.execute("SELECT courses.id FROM courses INNER JOIN course_starting_years ON course_starting_years.course_id = courses.id LEFT OUTER JOIN course_topic_relations ON course_topic_relations.course_starting_year_id = course_starting_years.id  WHERE course_topic_relations.activated_topic_id = #{self.id}").map { |ch| Course.find(ch['id']) }
	end

  def topic_and_level
    return topic.name + ' ' + topic.level.to_s
  end

  MAX_NCHARS_DISPLAYED_FOR_TOPIC_NAMES = 66

  def truncated_topic_and_level
    tname = topic.name.size > MAX_NCHARS_DISPLAYED_FOR_TOPIC_NAMES ?  topic.name[0..MAX_NCHARS_DISPLAYED_FOR_TOPIC_NAMES-1] + '...' : topic.name
    result = topic.level ? tname + ' ' + topic.level.to_s : tname
    return result
  end

###### For back compatibility and test - moro

	def topic_and_teacher_string
		topic_and_level
	end

  def name
    return topic.display_tooltip
  end

  def edit_or_create_name
    return lessons.empty? ? 'Crea le lezioni' : 'Modifica le lezioni'
  end

  # FIXME: this is an ugly hack, waiting to be fixed when the controller is
  # going to be fully REST-ized
  def edit_or_create_method
    return lessons.empty? ? "url_for(:controller => :lesson, :action => :create, :id => #{self.id})" : "mass_lesson_edit_at_activated_topic_path(#{self.id})"
  end

  # FIXME: this is an ugly hack, waiting to be fixed when the controller is
  # going to be fully REST-ized
  def edit_or_create_http_method
    return lessons.empty? ? :post : :get
  end

  # FIXME: this is a hack - the controller should be the ATController always
  # to be removed when lesson creation methods will be properly relocated
  def edit_or_create_controller
    return lessons.empty? ? :lesson : :activated_topic
  end

  def verify_compatibility
    result = true
    warnings.messages.clear
    total = 0
    lessons.each {|l| total += l.duration}
    unless total.minutes == duration.hours
      warnings << "Le #{total.to_f / 60.0} ore delle lezioni non corrispondono al monte ore del corso (#{duration} ore)"
      result = false
    end
    return result
  end

  #
  # lesson management
  #
	def delete_lessons
		if self.lessons.size == 0
			result = "Non sono attive lezioni per questo corso" 
		else
      self.lessons.clear
			self.reload
			result = "Tutte le lezioni di questo corso sono state cancellate"
		end
		return result
	end

  def clone_lessons(options = {})
    cloned = []
    lessons(options).each do
      |l|
      cloned << l.clone
    end
    return cloned
  end

  #
  # the new_lessons_from_form argument come in from the mass_lesson_edit
  # controller method. The argument is a hash organized like this:
  # { '0' => { lesson params }, '1' => { lesson params }, etc. }
  # generally these params have the temp_clone_id volatile attribute set
  # so they are considered clones of an already existing set.
  #
  def new_lessons_from_form(lessons_hash)
    return manage_lessons_hash(lessons_hash) { |args| self.lessons.build(args) }
  end

  def create_lessons_from_form(lessons_hash)
    return manage_lessons_hash(lessons_hash) { |args| self.lessons.create(args) }
  end

  def generate_lesson_hash
    result = HashWithIndifferentAccess.new
    lessons(:order => 'start_date').each_with_index { |l, i| result.update(i.to_s => l.hash) }
    return result
  end

  #
  # update_lessons_from_form(hash) takes the same form of mass_lesson_edit
  # parameters
  #
  def update_lessons_from_form(lessons_hash)
    old_ids = lessons.map { |l| l.id }
    result = manage_lessons_hash(lessons_hash) do
      |args|
      if args[:temp_clone_id] && args[:temp_clone_id] != 0
        old_ids.delete_if { |x| x == args[:temp_clone_id].to_i }
        l = lessons.find(args[:temp_clone_id])
        l.update_attributes!(args)
      else
        l = Lesson.create(args)
      end
      l
    end
    old_ids.each { |id| l = lessons.find(id); l.destroy }
    return result
  end

private

  def initialize(parms={})
    super(parms)
    @warnings = Warnings.new
  end

  #
  # lesson dates come from form as such:
  # { :start_date => TimeWithZone, :hour => Fixnum, :minute => Fixnum }
  # the :hour and :minute keys must be re-integrated inside the :start_date
  # TimeWithZone class
  #
  def manage_lesson_dates(hash)
    return Time.zone.create_from_hash(hash)
  end

  def manage_lessons_hash(lessons_hash)
    result = []
    lessons_hash.keys.numeric_sort.each do
      |k|
      args = HashWithIndifferentAccess.new(lessons_hash[k])
      args.update(:start_date => manage_lesson_dates(args[:start_date]), :activated_topic => self)
      args.delete(:id) # id can't be mass-assigned
      args[:temp_clone_id] = args[:temp_clone_id].to_i if args[:temp_clone_id] # make sure it is an int...
      l = yield(args)
      raise ActiveRecord::RecordInvalid.new(l) unless l.valid?
      result << l
    end
    return result
  end

public
  #
  # option group methods
  #

  include OptionGroupHelper

  class << self

	  def group_label
	    return 'Insegnamenti'
	  end

  end

  def option_value
    return truncated_topic_and_level + ' (' + all_annos + ')'
  end

public
  #
  # age methods
  #
  include AgeHelper # this implements the old? method too

  def age # this is required for the old? method to work
    return _age(year)
  end

  #
  # extra information report fields
  #

  DELIVERY_TYPES =
  {
    'TF'  => 'Teorico Frontale',
    'CPc' => 'Compartecipato Collettivo',
    'CPi' => 'Compartecipato Individuale',
  }
  DEFAULT_DELIVERY_TYPE = 'TF'

  class <<self

    def teaching_typology_selector
      return CourseTopicRelation.teaching_typology_selector
    end

    def delivery_type_selector
      key_order = ['TF', 'CPc', 'CPi']
      return key_order.map { |k| [DELIVERY_TYPES[k], k] }
    end

  end

  def delivery_type(csy_idx = 0)
    return common_delivery_type(csy_idx)
  end

  def delivery_type_extended(csy_idx = 0)
    return common_delivery_type(csy_idx) { |dt| DELIVERY_TYPES[dt] }
  end

  #
  # FIXME: the following method can probably be optimized very much, along with all the
  # others contained in this segment
  # 
  def all_delivery_types
    result = []
    course_starting_years.each_index { |i| result << common_delivery_type(i) }
    return result.uniq.join('/')
  end

private

  def common_delivery_type(csy_idx)
    dt = read_attribute(:delivery_type)
    type = ''
    type = course_topic_relations[csy_idx].teaching_typology == 'C' ? 1.to_s : 2.to_s if dt == 'CPi'
    dt = yield(dt) if block_given?
    return dt + type
  end

public
  #
  # active? method and corollaries
  #
  # activated_topic is *really* active when there are lessons related to it
  #
  def active?
    return !lessons.blank?
  end

  #
  # activity_report is a method used in reports. Returns 'A' when
  # ActivatedTopic is really active, 'S' otherwise
  #
  def activity_report
    return active? ? 'A' : 'S'
  end

  #
  # first_semester and second_semester are methods that emit an 'X' or ''
  #

  def first_semester
    return ((semester_start % 2) == 1) ? 'X' : ''
  end

  def second_semester
    return (((semester_start-1) % 2) == 1) ? 'X' : ''
  end

  #
  # all_courses: a string that combines all courses acronyms to be used
  #              in form, printings and reports
  #

  def all_courses
    return all_common_course_starting_years(:course_acronym)
  end

  def all_full_courses
    return all_common_course_starting_years(:full_course_acronym)
  end

  #
  # all_roman_years: a string that combines all roman_year attributes
  #              in form, printings and reports
  #

  def all_roman_years
    return all_common_course_starting_years(:roman_year)
  end

  def all_annos
    return all_common_course_starting_years(:anno)
  end
  #
  # all_teaching_typologies: a string that combines all teaching_typology attributes
  #              in form, printings and reports
  #

  def all_teaching_typologies
    return all_common(:course_topic_relations, :teaching_typology)
  end

  def all_full_teaching_typologies
    return all_common(:course_topic_relations, :full_teaching_typology)
  end

private

  def all_common_course_starting_years(meth)
    all_common(:course_starting_years, meth, :conditions => ["starting_year >= ?", CourseStartingYear::FINISHING_YEAR])
  end

  def all_common(assoc, meth, conds = {})
    return send(assoc).all(conds).map { |item| item.send(meth) }.sort.uniq.join('/')
  end

public
  #
  # Calendar Filtering management
  #

  include LessonFilteringHelper

  def generate_conditions
    return " (activated_topic_id = #{self.read_attribute(:id)}) "
  end

  #
  # form creation methods
  #

  def is_linked_to?(csy)
    return course_starting_years.exists?(csy.id)
  end

  def relation(csy)
    return is_linked_to?(csy) ? course_topic_relations.find_by_course_starting_year_id(csy.id) : nil
  end

  def selected_teaching_typology(ctr)
    return ctr ? ctr.teaching_typology : CourseTopicRelation::DEFAULT_TEACHING_TYPOLOGY
  end

  def selected_mandatory_flag(bool, ctr)
    return ctr ? (ctr.mandatory_flag == bool) : (CourseTopicRelation::DEFAULT_MANDATORY_FLAG == bool)
  end

  #
  # link_to_course_starting_years(args) expects:
  # * an array of hashs of course_starting years organized like this:
  #   { "xxx" => { :status => '0', :teaching_typology => 'C', :mandatory_flag
  #           => true, :course_year => 1 }, "yyy" => { :status => '1', ... }
  #   where 'xxx' and 'yyy' are ids for course starting year records,
  #   the :status fields denotes linking, and all other params are arguments
  #   of the course_topic_relations records to be created
  #
  def link_to_course_starting_years(csys)
    csys.each do
			|csy|
			csy.each do
        |id, args|
        dargs = args.stringify_keys
        switch = dargs.delete('status')
        if switch.to_s == '1'
          full_args = { :course_starting_year_id => id.to_i }
          full_args.update(dargs)
          ctr = course_topic_relations.create(full_args)
					raise(RuntimeError, "link of activated topic #{self.id} to course starting year #{csy} failed (#{ctr.errors.full_messages.join(', ')})") unless ctr.valid?
        end
			end
    end
  end

  def update_link_to_course_starting_years(csys)
		destroy_all_course_topic_relations
    link_to_course_starting_years(csys)
  end

  #
  # since the +:dependent => :destroy+ option doesn't work in conjunction with
  # the +:through+ one, we need to do the house cleaning ourselves. On top of
	# this, since the :course_topic_relations association has a condition to
	# show only current relations, we need to bypass the association to *really*
	# clear all associated records.
  #
  def destroy
		destroy_all_course_topic_relations
    super
  end

private

	def destroy_all_course_topic_relations
		#
		# Here we must make sure that all +course_topic_relations+ are cleared,
		# so we can't use the direct association which is already filtered
		#
		CourseTopicRelation.find_all_by_activated_topic_id(self.id).each { |ctr| ctr.destroy }
	end

end
