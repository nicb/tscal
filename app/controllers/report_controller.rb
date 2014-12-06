#
# $Id: report_controller.rb 298 2012-11-03 14:34:29Z nicb $
#

class ReportController < ApplicationController

  skip_before_filter :login_required

  include ReportHelper

  def index
    @course_selected = ''
    @activated_topics = ActivatedTopic.currently_active_topics
    initialize_selectors
    render(:action => :index)
  end

  def lessons
    @at = ActivatedTopic.find(params[:id])
  end

  def teacher
    @teacher = Teacher.find(params[:id])
  end

private

  def initialize_selectors
    %w(course teaching_typology delivery_type activation year semester teacher teacher_typology).each do
      |sel|
      eval("@#{sel}_selector = #{sel}_selector")
      eval("@#{sel}_selected = \"-1\"") # initialize to default blank selector
    end
  end

  def show_filtered_by_without_render(method, find_conditions = [], &block)
		res = []
	  initialize_selectors
	  eval("@#{method.to_s}_selected = @__tmpval__ = params[:id]")
    unless params[:id] == '-1'
      if block_given?
        res = yield(@__tmpval__)
      else
        find_conditions << @__tmpval__ if find_conditions.is_a?(Array) && !find_conditions.empty?
        res = ActivatedTopic.currently_active_topics(find_conditions)
      end
    else
	    res = ActivatedTopic.currently_active_topics
    end
		res
	end

	def show_filtered_by(method, find_options = {}, &block)
		@activated_topics = show_filtered_by_without_render(method, find_options, &block)

    render(:action => :index)
  end

public

  #
  # index filters
  #
  
  def show_filtered_by_course
    ats = show_filtered_by_without_render(:course_id, [ "((course_starting_years.course_id = courses.id) AND (course_starting_years.starting_year >= #{CourseStartingYear::FINISHING_YEAR}) AND (courses.id = ?))"])
		#
		# FIXME: I don't seem to be able to produce non-null only results with
	  # this query, so I resort to the hack below in order to make sure I don't
	  # end up with empty fields in my report
		#
		@activated_topics = ats.map { |at| at if at.course_topic_relations(true).size > 0 }.compact

    render(:action => :index)
  end

  def show_filtered_by_teaching_typology
    show_filtered_by(:teaching_typology, [ "(course_topic_relations.teaching_typology = ?)" ] )
  end

  def show_filtered_by_delivery_type
    show_filtered_by(:delivery_type, [ "(delivery_type = ?)"] )
  end

  def show_filtered_by_activation
    show_filtered_by(:activation) { |v| ActivatedTopic.currently_active_topics.map { |at| at if at.activity_report == v }.compact }
  end

  def show_filtered_by_year
		condition_string = ''
		unless params[:id] == '-1'
			params[:id] = CourseStartingYear.roman_to_julian_year(params[:id])
			condition_string = "(course_starting_years.starting_year = ?)"
		end
    show_filtered_by(:year, [ condition_string ])
  end

  def show_filtered_by_semester
    show_filtered_by(:semester) do
      |v|
      sel = { '1sem' => :first_semester, '2sem' => :second_semester }
      ActivatedTopic.currently_active_topics.map { |at| at if at.send(sel[v]) == 'X' }.compact 
    end
  end

  def show_filtered_by_teacher
    show_filtered_by(:teacher, [ "(teacher_id = ?)" ])
  end

  def show_filtered_by_teacher_typology
    show_filtered_by(:teacher_typology, [ "(users.teacher_typology = ?) AND (activated_topics.teacher_id = users.id)" ])
  end

end
