#
# $Id: course_topic_relation.rb 298 2012-11-03 14:34:29Z nicb $
#
class CourseTopicRelation < ActiveRecord::Base

  belongs_to :course_starting_year
  belongs_to :activated_topic

	has_many :lessons, :through => :activated_topic, :order => 'start_date, end_date'

  validates_presence_of :course_year, :course_starting_year_id, :activated_topic_id
  validates_numericality_of :course_year, :only_integer => true

  validates_uniqueness_of :course_starting_year_id, :scope => :activated_topic_id
  validates_uniqueness_of :activated_topic_id, :scope => :course_starting_year_id

  validates_associated :course_starting_year, :activated_topic

  TEACHING_TYPOLOGIES =
  [
    ['Carat.', 'C'],
    ['Base', 'B'],
    ['Affine', 'A'],
  ]
  TEACHING_TYPOLOGIES_HASH = { 'C' => 0, 'B' => 1, 'A' => 2 }
  TEACHING_TYPOLOGIES_HASH.default = 'C'
  DEFAULT_TEACHING_TYPOLOGY = TEACHING_TYPOLOGIES_HASH.default
  MANDATORY_FLAG =
  {
    true => 'Obbligatorio',
    false => 'A Scelta',
  }
  MANDATORY_FLAG.default = DEFAULT_MANDATORY_FLAG = true

  class <<self

    def teaching_typology_selector
      return TEACHING_TYPOLOGIES
    end

  end

  def full_teaching_typology
    return TEACHING_TYPOLOGIES[TEACHING_TYPOLOGIES_HASH[read_attribute(:teaching_typology)]][0]
  end

  def full_mandatory_flag
    return MANDATORY_FLAG[read_attribute(:mandatory_flag)]
  end

	def is_current?
		year_should_be = CourseStartingYear::CURRENT_AA - self.course_year + 1
		year_should_be == self.course_starting_year.starting_year
	end

end
