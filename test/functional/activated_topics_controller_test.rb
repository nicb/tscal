#
# $Id: activated_topics_controller_test.rb 298 2012-11-03 14:34:29Z nicb $
#
require 'test/test_helper'
require 'at/activated_topics_controller'

class At::ActivatedTopicsControllerTest < ActionController::TestCase

  fixtures :users, :topics, :courses, :course_starting_years

	def setup
    assert @admin = users(:moro)
    assert @admin.id
		assert @topic = Topic.first
    assert @topic.valid?
  	assert @teacher = Teacher.first
    assert @teacher.id
  	assert @credits = 2
  	assert @duration = 10
  	assert @semester_start = 1
  	assert @course_starting_year = CourseStartingYear.first 
    assert @start_date = Time.zone.local(2009, 11, 9)
    assert @lesson_generation_arguments = { 'Martedì' => {'dur' => 120, 'start_hour' => 12, 'start_minute' => 00},'Venerdì' => {'dur' => 300, 'start_hour' => 13, 'start_minute' => 15}}
    assert @prior_lesson_generation_arguments = { 'Martedì' => {'dur' => 120, 'start_hour' => 10, 'start_minute' => 00},'Venerdì' => {'dur' => 120, 'start_hour' => 11, 'start_minute' => 00}}
    assert @several_csys = {}
    CourseStartingYear.all.each do
      |csy|
      tt = CourseTopicRelation::TEACHING_TYPOLOGIES[(rand * (CourseTopicRelation::TEACHING_TYPOLOGIES.size.to_f-1)).round]
      mf = rand.round == 1 ? 'Obbligatorio' : 'A Scelta'
      this_csy = { 'teaching_typology' => tt[1], 'mandatory_flag' => mf, }
      this_csy.update('status' => '1') if rand.round == 1
      cy = CourseStartingYear::CURRENT_AA - csy.starting_year
      assert @several_csys.update(csy.id.to_s => this_csy)
      assert @several_csys[csy.id.to_s].update('course_year' => cy)
    end
	end

  test "should get index" do
    get :index
    assert_redirected_to :controller => :account, :action => :login
    get :index, {}, { :user => @admin }
    assert_response :success
    assert_template 'at/activated_topics/index'
    assert_not_nil assigns(:at_activated_topics)
  end

# TODO: this testing code should be implemented when the corresponding REST
#       code is. It won't work before
#
  test "should get new" do
    get :new
    assert_redirected_to :controller => :account, :action => :login
    get :new, {}, { :user => @admin }
    assert_response :success
    sel = assert_select('select#activated_topic_topic_id > option').size
    assert_equal Topic.all.size + 1, sel # add the 'Seleziona' tag
  end

  test "should create activated_topic" do
    csys_should_be = 0
    @several_csys.each { |k, v| csys_should_be += 1 if v['status'] == '1' }
    assert_routing({ :method => :post, :path => at_activated_topics_path }, { :controller => 'at/activated_topics', :action => 'create' })
    assert_difference('ActivatedTopic.count') do
      post :create, { 'commit' => 'Create', :activated_topic => {:topic => @topic, :teacher => @teacher, :credits => @credits, :duration => @duration, :semester_start => @semester_start, :course_starting_years => @several_csys } }, { :user => @admin }
    end

    assert at = assigns(:at_activated_topic)
    assert at.valid?
    assert_redirected_to at_activated_topic_url(at.id)
    assert_equal csys_should_be, at.course_starting_years(true).size
  end

  test "should show activated_topic" do
    get :show, { :id => activated_topics(:informatica_year_one).id }, { :user => @admin }
    assert_response :success
    assert_template 'at/activated_topics/show'
    assert at = assigns(:at_activated_topic)
    assert at.valid?
  end

  test "should get edit" do
    get :edit, { :id => activated_topics(:informatica_year_one).id }, { :user => @admin }
    assert_response :success
  end

  test "should update activated_topic" do
    csys_should_be = 0
    @several_csys.each { |k, v| csys_should_be += 1 if v['status'] == '1' }
    assert at = activated_topics(:informatica_year_one)
    assert 1, at.course_starting_years.size
    assert_recognizes({ :controller => 'at/activated_topics', :action => 'update', :id => at.id.to_s }, { :method => :put, :path => at_activated_topic_path(at.id) })
    put :update, { :id => at.id, :activated_topic => { :id => at.id, :course_starting_years => @several_csys } }, { :user => @admin }
    assert at_out = assigns(:at_activated_topic)
    assert_redirected_to at_activated_topic_path(at_out.id)
		assert @several_csys.each { |k, v| v['this_csy'] = CourseStartingYear.find(k) }
    assert_equal csys_should_be, at_out.course_starting_years(true).size, "input was: #{@several_csys.values.map { |v| [v['this_csy'].starting_year.to_s, v['course_year'].to_s, v['status'].to_s].join(', ') }.join('; ')} while output was: #{at_out.course_topic_relations(true).map { |ctr| [ctr.course_starting_year.starting_year.to_s, ctr.course_year.to_s].join(', ') }.join('; ')}"
  end

  test "should destroy activated_topic" do
    assert_difference('ActivatedTopic.count', -1) do
      delete :destroy, { :id => activated_topics(:informatica_year_one).id }, { :user => @admin }
    end

    assert_redirected_to at_activated_topics_path
  end

  test "auth filtering" do
    #
    # try getting the index without authorization
    #
    get :index
    assert_redirected_to(:controller => :account, :action => :login)
    #
    # now be authorized to do it
    #
    get :index, {}, { :user => @admin }
    assert_response :success
  end

  test "mass-edit lessons without changes" do
    clear_all_lessons
    mass_edit_lessons do
      assert_tag :tag => 'div', :attributes => { :class => 'valid_lesson' } # all lessons should be valid
      assert_no_tag :tag => 'div', :attributes => { :class => 'conflicting_lesson' } # no conflicts
    end
  end

  test "mass-edit lessons with changes without conflicts" do
    clear_all_lessons
    mass_edit_lessons(15) do
      assert_tag :tag => 'div', :attributes => { :class => 'valid_lesson' } # all lessons should be valid
      assert_no_tag :tag => 'div', :attributes => { :class => 'conflicting_lesson' } # no conflicts
    end
  end

  test "mass-edit lessons with changes WITH conflicts" do
    clear_all_lessons
    assert prior_at = activated_topics(:pianoforte_year_one)
    assert prior_at.valid?
    assert prior_lessons = Lesson.generate_lesson_list(prior_at, @start_date, @prior_lesson_generation_arguments)
    prior_lessons.each { |pl| assert pl.save; assert pl.valid? }
    mass_edit_lessons(-60, 15) do
      assert_tag :tag => 'div', :attributes => { :class => 'conflicting_lesson' } # all in conflict
      assert_no_tag :tag => 'div', :attributes => { :class => 'valid_lesson' } # no valid lessons
    end
  end

private

  def clear_all_lessons
    Lesson.all.clear # make sure no lessons are available at the beginning
    assert Lesson.all.blank?
  end

  def generate_parameters(lessons, submit, minutes_offset = 0)
    pars = { :lesson => {}, :id => assigns(:at).id, :commit => submit }
    assigns(:lessons).each_with_index do
      |l, i|
      k = i.to_s
      t = Time.zone.parse(l.start_date.to_s).since(minutes_offset.minutes)
      pars[:lesson][k] = {}
      pars[:lesson][k].update(:id => l.id, :temp_clone_id => l.temp_clone_id,
                              :start_date => { 'start_date(1i)' => t.year.to_s,
                                              'start_date(2i)' => t.month.to_s,
                                              'start_date(3i)' => t.day.to_s,
                                              'hour' => t.hour.to_s,
                                              'minute' => t.min.to_s, },
                              :duration => l.duration)
      yield(pars[:lesson][k]) if block_given?
    end
    return pars
  end

  def mass_edit_lessons(minutes_offset_beginning = 0, minutes_offset_end = nil)
    minutes_offset_end = minutes_offset_beginning unless minutes_offset_end
    assert at = activated_topics(:informatica_year_one)
    assert at.valid?
    assert lessons = Lesson.generate_lesson_list(at, @start_date, @lesson_generation_arguments)
    lessons.each { |l| assert l.new_record?; assert l.valid? }
    lessons.each { |l| assert l.save; assert l.valid? }
    assert !at.lessons.blank?
    assert_routing({ :method => :get, :path => mass_lesson_edit_at_activated_topic_path(at.id) }, { :controller => 'at/activated_topics', :action => 'mass_lesson_edit', :id => at.id.to_s })
    # get form
    get :mass_lesson_edit, { :id => at.id }, { :user => @admin}
    assert_response :success
    assert_template :mass_lesson_edit
    assert_not_nil assigns(:lessons)
    assert_not_nil assigns(:at)
    # verify
    pars = generate_parameters(assigns(:lessons), 'Verifica', minutes_offset_beginning)
    assert_routing({ :method => :put, :path => mass_lesson_edit_manage_at_activated_topic_path(at.id) },  { :controller => 'at/activated_topics', :action => 'mass_lesson_edit_manage', :id => at.id.to_s })
    put :mass_lesson_edit_manage, pars, { :user => @admin }
    assert_response :success
    assert_template :mass_lesson_edit
    yield
    assert_not_nil assigns(:lessons)
    assert_not_nil assigns(:at)
    # end
    pars = generate_parameters(assigns(:lessons), 'Fine', minutes_offset_end)
    assert_routing({ :method => :put, :path => mass_lesson_edit_manage_at_activated_topic_path(at.id) },  { :controller => 'at/activated_topics', :action => 'mass_lesson_edit_manage', :id => at.id.to_s })
    put :mass_lesson_edit_manage, pars, { :user => @admin }
    assert_redirected_to :controller => '/bo', :action => :index
    assert_not_nil assigns(:at)
  end

end
