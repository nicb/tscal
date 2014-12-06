#
# $Id: lesson_editing_test.rb 290 2012-07-31 01:45:43Z nicb $
#
require 'test/test_helper'

class LessonEditingTest < ActionController::IntegrationTest

  fixtures :all

  def setup
    assert @admin_user = users(:moro)
    assert @course = courses(:tds)
		assert @year_start = CourseStartingYear::CURRENT_AA - 2
		assert @year_end   = CourseStartingYear::CURRENT_AA
    assert @sy = CourseStartingYear::CURRENT_AA - 1
    assert @at = activated_topics(:informatica_year_two)
		assert @at.valid?
    #
    assert @start_date = sd = Time.zone.local(CourseStartingYear::CURRENT_AA, 11, 9).monday
    assert @new01_args = {"days"=>["0", "0", "Martedì", "0", "0", "Venerdì", "0"], "date"=>{"start(1i)"=>sd.year.to_s, "start(2i)"=>sd.month.to_s, "start(3i)"=>sd.day.to_s}}
    assert @new02_args = {"Martedì"=>{"dur"=>"60", "start_hour"=>"9", "start_minute"=>"30", "place_id"=>"1"}, "Venerdì"=>{"dur"=>"30", "start_hour"=>"12", "start_minute"=>"00", "place_id"=>"2"}}
  end

  test "create and then edit lessons without conflicts" do
    Lesson.all.clear
    n03_args_00 = generate_new03_args(@at, @start_date, @new02_args)
    lesson_count = n03_args_00.keys.size
	  #
	  # go to the login page
	  #
	  get url_for(:controller => :account, :action => :login)
    #
    # do everything in a session
    #
    open_session do
      |sess|
	    assert_response :success
	    assert_template 'account/login.html.erb'
	    #
	    # actually login
	    #
	    sess.post url_for(:controller => :account, :action => :login), { :user => { :login => @admin_user.login, :password => 'test' } }
      sess.assert_redirected_to :controller => :bo, :action => :index
	    assert_equal @admin_user, sess.session['user']
      #
      # select a course
      #
      resp = sess.get url_for(:controller => :bo, :action => :index), { :id => @course.id }
      sess.assert_response :success
      sess.assert_template 'bo/index'
      @year_start.upto(@year_end).each { |n| sess.assert_select('div#year>p>ul>li>a', n.to_s) }
      #
      # select a starting year
      #
      sess.get url_for(:controller => :bo, :action => :index), { :id => @course.id, :year => @sy }
      sess.assert_response :success
      sess.assert_template 'bo/index'
      sess.assert_select("div#topic>ul>li.activated_topic_item#t_#{@at.id}")
      #
      # select (== expand) a course
      #
      sess.xhr :post, url_for(:controller => :bo, :action => :expand_activated_topic), { :id => @at.id }
      sess.assert_response :success
      sess.assert_template 'bo/_expand_activated_topic'
      sess.assert_select('ul>li', "Nome del docente: #{@at.teacher.full_name}")
      assert_equal 'Crea le lezioni', @at.edit_or_create_name
      sess.assert_select('a', @at.edit_or_create_name)
      #
      # enter lesson creation on a course
      #
      # TODO: this part is to be overhauled completely and rest-ized
      #
      assert_difference('Lesson.count', lesson_count) do
	      sess.post eval(@at.edit_or_create_method), { :id => @at.id }
	      sess.assert_response :success
	      sess.assert_template 'lesson/new00'
	      sess.assert_select('div#container>h1', "Crea le lezioni di #{@at.topic.full_name}")
	      #
	      # select days
	      #
	      sess.post url_for(:controller => :lesson, :action => :new01), { :id => @at.id, :lesson => @new01_args }
	      sess.assert_response :success
	      sess.assert_template 'lesson/new01'
	      sess.assert_select('div#container>h1', "Crea le lezioni di #{@at.topic.full_name}")
	      #
	      # select times etc.
	      #
	      sess.post url_for(:controller => :lesson, :action => :new02), { :id => @at.id, :lesson => @new02_args }
	      sess.assert_response :success
	      sess.assert_template 'at/activated_topics/mass_lesson_edit'
	      sess.assert_select('div#container>h1', "Lezioni di #{@at.topic.full_name}")
	      #
        # NOTE: this already uses the new code - overhaul ABOVE here
	      # finalize creation and go back to index
	      #
        n03_args_01 = generate_new03_args(@at, @start_date, @new02_args)
	      sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_01, :commit => 'Verifica' }
	      sess.assert_response :success
	      sess.assert_template 'at/activated_topics/mass_lesson_edit'
	      sess.assert_select('div#container>h1', "Lezioni di #{@at.topic.full_name}")
        0.upto(lesson_count-1).each { |n| sess.assert_select("form>div.valid_lesson#lesson_#{n}") }
	      #
	      # finalize creation and go back to index
	      #
        sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_01, :commit => 'Fine' }
        sess.assert_redirected_to :controller => '/bo', :action => :index
      end
      #
      # now lessons are created, we start editing them
      #
      @at.reload
      lesson_count = @at.lessons.count
      sess.get eval(@at.edit_or_create_method) 
	    sess.assert_response :success
	    sess.assert_template 'at/activated_topics/mass_lesson_edit'
	    sess.assert_select('h1', "Lezioni di #{@at.topic.full_name}")
      0.upto(lesson_count-1).each { |n| sess.assert_select("form>div#lesson_#{n}>span>select#lesson_#{n}_start_date_start_date_3i") }
      #
      # let's edit them, without changes, verifying first
      #
      n03_args_02 = generate_new03_args(@at, @start_date, @new02_args)
      sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_02, :commit => 'Verifica' }
      sess.assert_response :success
	    sess.assert_template 'at/activated_topics/mass_lesson_edit'
	    sess.assert_select('h1', "Lezioni di #{@at.topic.full_name}")
      0.upto(lesson_count-1).each { |n| sess.assert_select("form>div.valid_lesson#lesson_#{n}") }
      #
      # then saving
      #
      n03_args_03 = generate_new03_args(@at, @start_date, @new02_args)
      sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_03, :commit => 'Fine' }
      sess.assert_redirected_to :controller => '/bo', :action => :index
      assert_lesson_shows(sess, @at)
      #
      # now let's try to remove a lesson from the form
      #
	    @at.reload
	    lesson_count = @at.lessons.count
	    tbr = 1 # lesson to be removed
      removed_lesson = @at.lessons[tbr]
      assert_difference('Lesson.count', -1) do
	      sess.get eval(@at.edit_or_create_method) 
		    sess.assert_response :success
		    sess.assert_template 'at/activated_topics/mass_lesson_edit'
	      sess.xhr :delete, remove_at_lesson_url(tbr)
		    sess.assert_response :success
		    sess.assert_template 'at/lessons/_remove'
	      sess.assert_select('p', "Lezione #{tbr + 1} - Rimossa!")
	      n03_args_04 = generate_new03_args(@at, @start_date, @new02_args)
	      n03_args_04[(tbr-1).to_s] = {} # we remove the lesson that has been removed
	      sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_04, :commit => 'Verifica' }
		    sess.assert_select('h1', "Lezioni di #{@at.topic.full_name}")
	      sess.assert_no_tag(:tag => "div#lesson_#{tbr}", :descendant => { :tag => 'span', :descendant => { :tag => :select }})
	      0.upto(lesson_count-2).each { |n| sess.assert_select("form>div#lesson_#{n}>span>select#lesson_#{n}_start_date_start_date_3i") } # skip the first one
	      sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_04, :commit => 'Fine' }
	      sess.assert_redirected_to :controller => '/bo', :action => :index
      end
      assert_lesson_shows(sess, @at)
      assert_lesson_show(sess, removed_lesson, @new02_args.keys.size - 1) # we should have one lesson less that week
      #
      # now let's try to ADD five lessons from the form
      #
	    @at.reload
      lessons_tba = 5
	    final_lesson_count = @at.lessons.count + lessons_tba
      assert_difference('Lesson.count',5) do
	      sess.get eval(@at.edit_or_create_method) 
		    sess.assert_response :success
		    sess.assert_template 'at/activated_topics/mass_lesson_edit'
	      n03_args_next = generate_new03_args(@at, @start_date, @new02_args)
        1.upto(lessons_tba) do
          |n|
	        sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_next, :commit => "Aggiungi un'altra lezione" }
          lidx = @at.lessons.count + n
		      sess.assert_response :success
		      sess.assert_template 'at/activated_topics/mass_lesson_edit'
		      sess.assert_select('h1', "Lezioni di #{@at.topic.full_name}")
          sess.assert_select("div.valid_lesson#lesson_#{lidx-1}")
	        0.upto(lidx-1).each { |n| sess.assert_select("form>div.valid_lesson#lesson_#{n}>span>select#lesson_#{n}_start_date_start_date_3i") }
          n03_args_next = add_a_new_lesson_to_args(n03_args_next)
        end
 	      sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_next, :commit => 'Fine' }
	      sess.assert_redirected_to :controller => '/bo', :action => :index
      end
      assert_lesson_shows(sess, @at)
    end
  end

  test "create and then edit lessons with wrong dates" do # i.e.: invalid dates
    Lesson.all.clear
    assert n03_args_00 = generate_new03_args(@at, @start_date, @new02_args)
    assert lesson_count = n03_args_00.keys.size
	  #
	  # go to the login page
	  #
	  get url_for(:controller => :account, :action => :login)
    #
    # do everything in a session
    #
    open_session do
      |sess|
	    assert_response :success
	    assert_template 'account/login.html.erb'
	    #
	    # actually login
	    #
	    sess.post url_for(:controller => :account, :action => :login), { :user => { :login => @admin_user.login, :password => 'test' } }
      sess.assert_redirected_to :controller => :bo, :action => :index
	    assert_equal @admin_user, sess.session['user']
      #
      # select a course
      #
      resp = sess.get url_for(:controller => :bo, :action => :index), { :id => @course.id }
      sess.assert_response :success
      sess.assert_template 'bo/index'
      @year_start.upto(@year_end).each { |n| sess.assert_select('div#year>p>ul>li>a', n.to_s) }
      #
      # select a starting year
      #
      sess.get url_for(:controller => :bo, :action => :index), { :id => @course.id, :year => @sy }
      sess.assert_response :success
      sess.assert_template 'bo/index'
      sess.assert_select("div#topic>ul>li.activated_topic_item#t_#{@at.id}")
      #
      # select (== expand) a course
      #
      sess.xhr :post, url_for(:controller => :bo, :action => :expand_activated_topic), { :id => @at.id }
      sess.assert_response :success
      sess.assert_template 'bo/_expand_activated_topic'
      sess.assert_select('ul>li', "Nome del docente: #{@at.teacher.full_name}")
      assert_equal 'Crea le lezioni', @at.edit_or_create_name
      sess.assert_select('a', @at.edit_or_create_name)
      #
      # enter lesson creation on a course
      #
      # TODO: this part is to be overhauled completely and rest-ized
      #
      assert_difference('Lesson.count', lesson_count) do
	      sess.post eval(@at.edit_or_create_method), { :id => @at.id }
	      sess.assert_response :success
	      sess.assert_template 'lesson/new00'
	      sess.assert_select('div#container>h1', "Crea le lezioni di #{@at.topic.full_name}")
	      #
	      # select days
	      #
	      sess.post url_for(:controller => :lesson, :action => :new01), { :id => @at.id, :lesson => @new01_args }
	      sess.assert_response :success
	      sess.assert_template 'lesson/new01'
	      sess.assert_select('div#container>h1', "Crea le lezioni di #{@at.topic.full_name}")
	      #
	      # select times etc.
	      #
	      sess.post url_for(:controller => :lesson, :action => :new02), { :id => @at.id, :lesson => @new02_args }
	      sess.assert_response :success
	      sess.assert_template 'at/activated_topics/mass_lesson_edit'
	      sess.assert_select('div#container>h1', "Lezioni di #{@at.topic.full_name}")
	      #
        # NOTE: this already uses the new code - overhaul ABOVE here
	      # put a wrong date in the system
	      #
        n03_args_01 = generate_new03_args(@at, @start_date, @new02_args)
        n03_args_01['0']['start_date']['start_date(2i)'] = 2.to_s  # February
        n03_args_01['0']['start_date']['start_date(3i)'] = 31.to_s # February 31st
	      sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_01, :commit => 'Verifica' }
	      sess.assert_response :redirect
        assert_equal "La data 31/2/#{CourseStartingYear::CURRENT_AA} non esiste o è errata", sess.flash[:notice]
        sess.assert_redirected_to mass_lesson_edit_manage_at_activated_topic_path(@at)
	      #
	      # correct the mistake
	      #
        n03_args_01['0']['start_date']['start_date(3i)'] = 27.to_s # February 27
	      sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_01, :commit => 'Verifica' }
	      sess.assert_response :success
	      sess.assert_template 'at/activated_topics/mass_lesson_edit'
	      sess.assert_select('div#container>h1', "Lezioni di #{@at.topic.full_name}")
        0.upto(lesson_count-1).each { |n| sess.assert_select("form>div.valid_lesson#lesson_#{n}") }
        #
        # finalize creation and go back to index
	      #
        sess.put mass_lesson_edit_manage_at_activated_topic_path(@at), { :lesson => n03_args_01, :commit => 'Fine' }
        sess.assert_redirected_to :controller => '/bo', :action => :index
      end
    end
  end

  #
  # TODO: add tests for:
  # 1) adding/removing lessons *before* saving
  # 2) managing conflicting lessons (check warnings in particular)
  #

private

  #
  # NOTE: at.generate_lesson_hash cannot be used because it requires
  # lessons to be already created, something we can't grant here.
  #
  def generate_new03_args(at, start_date, new02_args)
    llist = at.lessons.blank? ? Lesson.generate_lesson_list(at, start_date, new02_args) : at.lessons
    result = {}
    llist.each_with_index do
      |l, i|
      result.update(i.to_s => l.to_hash_clone)
    end
    return result
  end

  def add_a_new_lesson_to_args(args)
    lkeys = args.keys.numeric_sort
    last_lesson = args[lkeys.last]
    new_lesson = last_lesson.dup
    new_date = Time.zone.create_from_hash(last_lesson['start_date']) + 7.days
    new_lesson['start_date'].update('start_date(1i)' => new_date.year.to_s, 'start_date(2i)' => new_date.month.to_s, 'start_date(3i)' => new_date.day.to_s)
    new_lesson.delete('id')
    new_lesson.delete('temp_clone_id')
    new_key = (lkeys.last.to_i + 1).to_s
    args.update(new_key => new_lesson)
    return args
  end

  class NoLessonsAvailable < ActiveRecord::RecordNotFound
  end

  def assert_lesson_shows(sess, at)
    result = nil
    raise(NoLessonsAvailable, "\"#{at.topic_display}\" should have lessons and has none") if at.lessons.blank?
    at.lessons.each do
      |l|
      result = assert_lesson_show(sess, l)
    end
    return result
  end

  def assert_lesson_show(sess, lesson, condition = true)
    sd = lesson.start_date
    sess.get url_for(:controller => :calendar, :action => :show_html), { :day => sd.day, :month => sd.month, :year => sd.year }
    sess.assert_response :success
    sess.assert_template 'calendar/show_html'
    return sess.assert_select('div.lesson_title', condition, lesson.topic_display)
  end

end
