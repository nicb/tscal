#
# $Id: lesson_controller.rb 250 2010-04-10 12:38:28Z moro $
#

require 'datetime'
require 'time_zone'

class LessonController < ApplicationController

  def create
    flash['new00_params'] = params
    @at = ActivatedTopic.find(params[:id])
    @full_params = params
    render(:action => :new00)
  end

  def new01
    flash['new01_params'] = params
    safe_new(flash['new00_params'], params[:lesson]) do
      @at = ActivatedTopic.find(params[:id])
      @days = params[:lesson][:days].delete_if{ |x| x == '0'}
      d = params[:lesson][:date]
      @date_start = Time.zone.verified_local(d["start(1i)"].to_i,d["start(2i)"].to_i,d["start(3i)"].to_i)
      render(:action => :new01)
    end
  end

  def new02
    flash['new02_params'] = params
    new_pars = {};
    new_pars.update(:lesson => params[:lesson], :date_start => params[:date_start])
    safe_new(flash['new01_params'], new_pars) do
	    @at = ActivatedTopic.find(params[:id])
	    date_start = Time.zone.at(params[:date_start].to_i)
	    wdays = params[:lesson].dup
	    wdays.each do
	      |k, v|
	      wdays[k][:start_hour] = wdays[k]["time(4i)"]
	      wdays[k][:start_minute] = wdays[k]["time(5i)"]
				wdays[k][:place_id] = wdays[k]["place_id"]
	    end
      @lessons = Lesson.generate_lesson_list(@at, date_start, wdays)
#     render(:action => :new02)
      # FIXME: all the above is *almost* obsolete and deprecated
      #        here we're switching to the new code
      render(:template => 'at/activated_topics/mass_lesson_edit')
    end
  end

	def new02_verify
    new02_new03_common(:new){ render(:action => :new02) }
	end

	def almost_new03
		if params[:commit] == "Fine"
			new03
		else
			new02_verify
		end
	end

  def new03
		@at = ActivatedTopic.find(params[:id])
		if @at.lessons.blank?
    	new02_new03_common(:create) { redirect_to :controller => :bo, :action => :index }
      return
		else
			invalid = false
			old_lessons = @at.lessons
			new02_new03_common(:create) do
				@lessons.each do
					|l|
					unless l.valid?
						@lessons.each {|ll| ll.destroy}
						@lessons = @at.lessons
						invalid = true
						break
					end
				end
				old_lessons.each{|ol| ol.destroy} unless invalid
				render(:action => :new02)
			end
		end
  end

  def new02_new03_common(method)
	  @at = ActivatedTopic.find(params[:id]) unless @at
    safe_new(flash['new02_params'], params[:lesson]) do
      lessons = params[:lesson]
 			@lessons = []
 			lessons.each do
 	      |n, l|
        sd = l[:start_date]
 	      d = Time.zone.verified_local(sd["start_date(1i)"].to_i,sd["start_date(2i)"].to_i,sd["start_date(3i)"].to_i,sd["hour"].to_i,sd["minute"].to_i)
 	      @lessons << Lesson.send(method, :activated_topic => @at, :start_date => d, :duration => l["duration"].to_i, :place_id => l["place_id"].to_i)
 	    end
			@lessons.sort!{|a, b| a.start_date <=> b.start_date}
			yield
    end
  end

private

  def safe_new(old_pars, new_pars)
    begin
      yield
    rescue ArgumentError
      flash[:notice] = "La data #{$!} non esiste o è errata"
      old_pars.update(new_pars)
      redirect_to(old_pars)
    end
  end

public

	def edit
    @at = ActivatedTopic.find(params[:id])
    @lessons = @at.clone_lessons.sort!{|a, b| a.start_date <=> b.start_date}
		render(:action => :new02)
	end

	def edit_lesson
		@lesson = Lesson.find(params[:id])
		render(:action => :edit_lesson)
	end

	def delete
		lesson = Lesson.find(params[:id])
		lesson.destroy
		d = Time.zone.parse(params[:date])
		redirect_to :controller => :calendar, :action => :show_js, :day => d.day, :month => d.month, :year => d.year, :filter => 'Mostra_Tutto'
	end

	def new_lesson
		d = Time.zone.parse(params[:date])
		dur = params[:duration].to_i
		at = ActivatedTopic.find_by_id(params[:at])
		i = params[:index].to_i + 0.1
		l = Lesson.new(:activated_topic => at, :start_date => d, :duration => dur)
		render(:partial => 'new_lesson', :update => i, :object => l, :locals => { :index => i.to_s })
	end

	def update
    @lesson = Lesson.find(params[:id])
    lpars = params['lesson'].dup
    dh = lpars.delete(:start_date)
    lpars[:start_date] = Time.zone.create_from_hash(dh)

    respond_to do |format|
      if @lesson.update_attributes!(lpars)
        flash[:notice] = 'Lesson was successfully updated.'
        format.html { redirect_to(:controller => :calendar, :action => :show_js) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lesson.errors, :status => :unprocessable_entity }
      end
    end
  end

end
