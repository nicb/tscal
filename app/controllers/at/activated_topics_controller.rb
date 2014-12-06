#
# $Id: activated_topics_controller.rb 292 2012-08-23 16:26:37Z nicb $
#
require 'array'

module At

	class ActivatedTopicsController < ApplicationController

    layout 'activated_topics'

# TODO: these need to be refactored from the old ActivatedTopics controller
 	  # GET /at/activated_topics
 	  # GET /at/activated_topics.xml
 	  def index
 	    @at_activated_topics = ActivatedTopic.find(:all)
 	
 	    respond_to do |format|
 	      format.html # index.html.erb
 	      format.xml  { render :xml => @at_activated_topics }
 	    end
 	  end

 	  # GET /at/activated_topics/1
 	  # GET /at/activated_topics/1.xml
 	  def show
 	    @at_activated_topic = ActivatedTopic.find(params[:id])
 	
 	    respond_to do |format|
 	      format.html # show.html.erb
 	      format.xml  { render :xml => @at_activated_topic }
 	    end
 	  end
 	
 	  # GET /at/activated_topics/new
 	  # GET /at/activated_topics/new.xml
 	  def new
      session[:return_to] = url_for(:action => 'new')
 	    @at_activated_topic = ActivatedTopic.new
 	
 	    respond_to do |format|
 	      format.html # new.html.erb
 	      format.xml  { render :xml => @at_activated_topic }
 	    end
 	  end
 	
 	  # GET /at/activated_topics/1/edit
 	  def edit
 	    @at_activated_topic = ActivatedTopic.find(params[:id])
 	  end
 	
 	  # POST /at/activated_topics
 	  # POST /at/activated_topics.xml
 	  def create
      csys_to_be_linked = params[:activated_topic].delete('course_starting_years')
 	    @at_activated_topic = ActivatedTopic.new(params[:activated_topic])
 	
 	    respond_to do |format|
 	      if @at_activated_topic.save
 	        flash[:notice] = 'ActivatedTopic was successfully created.'
          @at_activated_topic.link_to_course_starting_years([ csys_to_be_linked ])
 	        format.html { redirect_to(at_activated_topic_url(@at_activated_topic)) }
 	        format.xml  { render :xml => @at_activated_topic, :status => :created, :location => @at_activated_topic }
 	      else
 	        flash[:notice] = "Errors while creating Activated Topic: #{@at_activated_topic.errors.full_messages.join(', ')}"
          params[:activated_topics].update(:course_starting_years => csys_to_be_linked)
 	        format.html { render :action => "new" }
 	        format.xml  { render :xml => @at_activated_topic.errors, :status => :unprocessable_entity }
 	      end
 	    end
 	  end
 	
 	  # PUT /at/activated_topics/1
 	  # PUT /at/activated_topics/1.xml
 	  def update
 	    @at_activated_topic = ActivatedTopic.find(params[:id])
      csys_to_be_linked = params[:activated_topic].delete('course_starting_years')
			params[:activated_topic].delete('id')
 	    @at_activated_topic.update_attributes(params[:activated_topic])
 	
 	    respond_to do |format|
 	      if @at_activated_topic.save
          @at_activated_topic.update_link_to_course_starting_years([ csys_to_be_linked ])
 	        flash[:notice] = 'ActivatedTopic was successfully updated.'
 	        format.html { redirect_to(at_activated_topic_path(@at_activated_topic)) }
 	        format.xml  { head :ok }
 	      else
 	        format.html { render :action => "edit" }
 	        format.xml  { render :xml => @at_activated_topic.errors, :status => :unprocessable_entity }
 	      end
 	    end
 	  end
 	
 	  # DELETE /at/activated_topics/1
 	  # DELETE /at/activated_topics/1.xml
 	  def destroy
 	    @at_activated_topic = ActivatedTopic.find(params[:id])
 	    @at_activated_topic.destroy
 	
 	    respond_to do |format|
 	      format.html { redirect_to(at_activated_topics_url) }
 	      format.xml  { head :ok }
 	    end
 	  end
	
	  #
	  # mass lesson creation and editing
	  #
	  class NoLessonsToBeEdited < ActiveRecord::ActiveRecordError
	  end
	
    # GET /at/activated_topics/:id/mass_lesson_edit
	  def mass_lesson_edit
	    @at = ActivatedTopic.find(params[:id])
	    raise(NoLessonsToBeEdited, "Activated topic \"#{@at.topic.name}\"(#{@at.id}) has no lessons to be edited") if @at.lessons.blank?
	    @lessons = @at.clone_lessons(:order => 'start_date')
      @lessons.each { |l| l.verify_compatibility }
	  end

    class UnknownAction < StandardError
    end

    # PUT /at/activated_topics/:id/mass_lesson_edit_manage
    def mass_lesson_edit_manage
      begin
	      case params[:commit]
	        when 'Fine' : mass_lesson_edit_end(params)
	        when "Aggiungi un'altra lezione" : mass_add_a_new_lesson(params)
	        when 'Verifica' : mass_lesson_edit_verify(params)
	        else raise(UnknownAction, "Unknown action #{params[:commit]}")
	      end
      rescue ActiveSupport::TimeZone::InvalidDate => msg
        ridx = msg.message.rindex(/\s+[0-9]/)
        clean_msg = msg.message[ridx..msg.message.size-1].strip
	      flash[:notice] = "La data #{clean_msg} non esiste o è errata"
	      redirect_to mass_lesson_edit_manage_at_activated_topic_url(params[:id]), params
      end
    end

  private

    def mass_add_a_new_lesson(pars)
      args = pars.dup
      lkeys = args['lesson'].keys.numeric_sort
      last_lesson = args['lesson'][lkeys.last]
      new_lesson = last_lesson.dup
      new_date = Time.zone.create_from_hash(last_lesson['start_date']) + 7.days
      new_lesson['start_date'].update('start_date(1i)' => new_date.year.to_s, 'start_date(2i)' => new_date.month.to_s, 'start_date(3i)' => new_date.day.to_s)
      new_lesson.delete('id')
      new_lesson.delete('temp_clone_id')
      new_key = (lkeys.last.to_i + 1).to_s
      args['lesson'].update(new_key => new_lesson)
      mass_lesson_edit_verify(args)
    end

    def mass_lesson_edit_end(pars)
	    @at = ActivatedTopic.find(pars[:id])
      m = @at.lessons.blank? ? 'create' : 'update'
      meth = m + '_lessons_from_form'
      @at.send(meth, pars[:lesson])
      @at.lessons.each { |l| l.verify_compatibility }
      redirect_to(:controller => '/bo', :action => :index)
    end
	
    def mass_lesson_edit_verify(pars)
	    @at = ActivatedTopic.find(pars[:id])
      @lessons = @at.new_lessons_from_form(pars[:lesson])
      @lessons.each { |l| l.verify_compatibility }
      render(:action => :mass_lesson_edit)
    end

	end

end
