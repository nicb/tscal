#
# $Id: bo_controller.rb 296 2012-09-05 13:20:37Z nicb $
#
class BoController < ApplicationController

  def index
    @course=Course.find(params[:id]) if params[:id]
    if params[:year]
      @year = params[:year]
      @activated_topics = @course.course_starting_years.find_by_starting_year(@year).activated_topics
      @teachers=@course.teachers(@year)
    end
    @courses=Course.all
    respond_to do |format|
      format.html # index.html.erb
      #format.xml  { render :xml => @activated_topics }
    end
  end

  def expand_activated_topic
    at = ActivatedTopic.find(params[:id])
    render(:partial => 'expand_activated_topic', :object => at)
  end

  def expand_teacher
    t = Teacher.find(params[:id])
    render(:partial => 'expand_teacher', :object => t)
  end

  def close_activated_topic
    at = ActivatedTopic.find(params[:id])
    render(:partial => 'close_activated_topic', :object => at)
  end

  def close_teacher
      t = Teacher.find(params[:id])
    render(:partial => 'close_teacher', :object => t)
  end

  def close_new_course
    c = Course.create(params['bo'])
    #redirect_to(:controller => :bo, :action => :index)
    render(:partial => 'close_new_course')
  end

  def expand_new_course
    render(:partial => 'expand_new_course')
  end

  def expand_new_year
    render(:partial => 'expand_new_year')
  end

  def close_new_year
    course = Course.find(params[:id])
    course.activate(params[:bo][:year])
    render(:partial => 'close_new_year')
  end

  def expand_new_topic
    course = Course.find(params[:id])
    csy = course.course_starting_years.find_by_starting_year(params[:sy])
    render(:partial => 'expand_new_topic', :object => course, :locals => { :csy => csy })
  end

  def close_new_topic
    bo = params[:bo]
    ats = params[:activated_topic]
    this_csy = CourseStartingYear.find(params[:id])
    selected_csys = []
    ats[:course_starting_years].each { |k, v| selected_csys << k.to_i if v.has_key?('status') && v['status'] == '1' }
    selected_csys << this_csy.id
    at = ActivatedTopic.create(bo)
    csys = CourseStartingYear.find(selected_csys.uniq)
    csys.each { |csy| csy.course_topic_relations.create(:activated_topic_id=>at.id, :course_year => csy.arabic_year) }
    coll = this_csy.activated_topics(true)
		render(:partial => 'close_new_topic', :object => coll, :locals => { :course_id => this_csy.id })
  end
	
	def delete_lessons
		at = ActivatedTopic.find(params[:id])
		at.lessons.map{|l| l.destroy}
		at.reload
		render(:partial => 'close_activated_topic', :object => at)
	end

end
