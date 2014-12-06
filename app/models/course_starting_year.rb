#
# $Id: course_starting_year.rb 294 2012-09-02 04:58:25Z nicb $
#
class CourseStartingYear < ActiveRecord::Base

  belongs_to :course
  has_many :course_topic_relations, :dependent => :destroy
  has_many :activated_topics, :through => :course_topic_relations

  validates_presence_of :course_id, :starting_year, :color
  validates_uniqueness_of :starting_year, :scope => :course_id

  #
  # +topic_activate+ is passed a hash of options which are needed to create
  # the activated topic. If a +:course_year+ field is present, then the creation
  # attempts to short-cut the creation of a +CourseTopicRelation+ as well
  # between all these entities
  #
  def topic_activate(options = {})
    cy = nil
    options.stringify_keys!
    ctr_args = options.delete('ctr_args') if options.has_key?('ctr_args')
    at = ActivatedTopic.create(options)
    if at.valid? && ctr_args
      key = self.id.to_s
			full_ctr_args = { key => ctr_args }
      at.link_to_course_starting_years([ full_ctr_args ]) 
    end
    at
  end

  alias :activate_topic :topic_activate

  def teachers
    return activated_topics.map { |at| at.teacher }
  end

  #
  # option group methods
  #

  include OptionGroupHelper

  class << self

	  def group_label
	    return 'Corsi'
	  end

		#
		# FIXME: +running_years+ should really not be a class method but rather
		# a method connected to the number of years of each course, because it
		# depends on the duration of the course. However, this implies heavy
		# modifications of the +CourseStartingYear+ code (essentially: remove all
		# the ACADEMIC_YEAR cruft and replace it with a proper model) so it is
		# postponed until 0.3.0
		#
    def running_years
      all(:conditions => ["starting_year >= ?", FINISHING_YEAR], :include => [ :course ], :order => 'courses.name, starting_year desc')
    end

    def sorted_all
      return all(:joins => 'inner join courses on course_id = courses.id', :order => 'courses.name, starting_year desc')
    end

  end

  #
  # utility for external objects
  #
  def course_acronym
    return course.acronym
  end

  def full_course_name
    return full_course_common(:name)
  end

  def full_course_acronym
    return full_course_common(:acronym)
  end

  alias :option_value :full_course_name

private

  def full_course_common(meth)
    return course.send(meth) + ' (' + anno + ')'
  end

public
  #
  # age methods
  #
  include AgeHelper # this implements the old? method too

  def age # this is required for the old? method to work
    return _age(starting_year)
  end

  #
  # anno methods
  #
  CURRENT_AA = 2012
  FINISHING_YEAR = CURRENT_AA-2
  ANNO_MAP =
  {
    CURRENT_AA => 'Primo Anno',
    CURRENT_AA-1 => 'Secondo Anno',
    CURRENT_AA-2 => 'Terzo Anno',
  }
  ANNO_MAP.default = 'Fuori Corso'
  ROMAN_YEAR_MAP =
  {
    CURRENT_AA => 'I',
    CURRENT_AA-1 => 'II',
    CURRENT_AA-2 => 'III',
  }
  ROMAN_YEAR_MAP.default = 'FC'

  def anno
    return ANNO_MAP[starting_year]
  end

  def roman_year
    return ROMAN_YEAR_MAP[starting_year]
  end

	def arabic_year
		CURRENT_AA - self.starting_year + 1
	end

  class <<self

    def roman_to_julian_year(y)
      return ROMAN_YEAR_MAP.invert[y]
    end

  end

  #
  # Calendar Filtering management
  #

  include LessonFilteringHelper

end
