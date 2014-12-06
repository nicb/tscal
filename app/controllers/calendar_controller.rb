#
# $Id: calendar_controller.rb 245 2010-03-15 14:43:37Z mtisi $
#

require 'calendar'
require 'datetime'

class CalendarController < ApplicationController

  skip_before_filter :login_required
  
  class InvalidDate < ArgumentError; end

  def show_html
    begin
      t = Time.zone.local(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    rescue(ArgumentError)
      t = Time.zone.now
    end
    @cwd = Calendar::Display::Week::Display.new(t)
    begin
      lessons = Lesson.prepare_data_set(@cwd.week_start, @cwd.week_end, params[:filter])
      @cwd.add_data_set(lessons)
      @cd = @cwd.renderer
    rescue InvalidDate, Lesson::InvalidFilter, NoMethodError
      logger.error('>>> ERROR!: ' + $! + ', the event will not be displayed <<<')
    end
    @group_options = build_selector_options
    @selected_option = params[:filter] ? params[:filter] :  @group_options[0].group[0].option_key
    session[:return_to] = url_for(:controller => 'calendar', :action => 'show_html', :day => params[:day].to_i, :month => params[:month].to_i, :year => params[:year].to_i)
  end

  def show_js
    @group_options = build_selector_options
    @selected_option = params[:filter] ? params[:filter] :  @group_options[0].group[0].option_key
    session[:return_to] = url_for(:controller => 'calendar', :action => 'show_js')
  end

  def get_lessons_json
    @start = Time.at(params[:start].to_i);
    @end = Time.at(params[:end].to_i);
    @filter = params[:filter];
    @lessons = Lesson.prepare_data_set(@start, @end, @filter).flatten
    respond_to do |format|
      format.js
    end
  end

  private


  def build_selector_options
    OptionGroupHelper::FakeGroup.clear
    fg = OptionGroupHelper::FakeGroup.new('Mostra Tutto')
    result = []
    result << OptionGroupHelper::FakeGroup
    result << Course
    result << CourseStartingYear
    result << ActivatedTopic
    result << Teacher
    return result
  end

end
