#
# $Id: course.rb 245 2010-03-15 14:43:37Z mtisi $
#
class Course < ActiveRecord::Base

  has_many :course_starting_years, :dependent => :destroy, :order => 'starting_year'

  validates_presence_of :name, :duration, :acronym
  validates_uniqueness_of :name, :acronym
  validates_numericality_of :duration
	validates_length_of       :acronym,    :within => 1..5


  MAXIMUM_NAME_SIZE = 7

  protected

  class << self
 
    def selection
      cs = all(:order => "name").map {|c| [c.name, c.id]}
      return cs
    end
 
  end

  public

  include OptionGroupHelper

  class << self

	  def group_label
	    return 'Corso'
	  end

  end

  def option_value
    return name
  end
  
  include LessonFilteringHelper

  def generate_conditions
    conds = course_starting_years.map { |csy| "(course_starting_years.id = #{csy.id})" }
    return '(' + conds.join(' or ') + ") and course_topic_relations.course_starting_year_id = course_starting_years.id and activated_topics.id = course_topic_relations.activated_topic_id and activated_topics.id = lessons.activated_topic_id"
  end

  def generate_query_hash(conditions)
    return { :select => 'lessons.*', :from => 'activated_topics,course_starting_years,course_topic_relations,courses,lessons', :conditions => conditions }
  end

  def activate(year, col = '#f0f0f0')
    return course_starting_years.create(:starting_year => year, :color => col)
  end

  def deactivate(year)
    cy = course_starting_years.find_by_starting_year(year)
    cy.destroy
  end

  private
  def topic_proxy(year, force_reload, &block)
    result = []
    c = course_starting_years(force_reload).find_by_starting_year(year)
    result = c.activated_topics(force_reload).map { |at| yield(at) } if c
    return result
  end

  public

  def topics(year, force_reload = false)
    return topic_proxy(year, force_reload) { |at| at.topic }
  end

  def teachers(year, force_reload = false)
    return topic_proxy(year, force_reload) { |at| at.teacher }
  end

	def display
		return name.size > MAXIMUM_NAME_SIZE ? acronym : name
	end

  def display_tooltip; return name; end

end
