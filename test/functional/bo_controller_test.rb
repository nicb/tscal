#
# $Id: bo_controller_test.rb 298 2012-11-03 14:34:29Z nicb $
#
require 'test/test_helper'

class BoControllerTest < ActionController::TestCase

  fixtures :users, :courses, :course_starting_years, :topics, :activated_topics

  def setup
    #
    # the admin has to be created (== cannot be taken from fixtures) because
    # it requires the password confirmation which cannot reside in the
    # fixtures
    #
    assert @admin = Admin.create(:first_name => 'Tester', :last_name => 'Tester', :login => 'tester',
                                 :password => 'testtest', :password_confirmation => 'testtest',
                                 :email => 'nobody@nowhere.com')
    assert @admin.valid?, "User \"#{@admin.login}\" is not valid: #{@admin.errors.full_messages.join(', ')}"
		assert @course = courses(:tds)
		assert @csy = course_starting_years(:tds_one)
		assert @csy.valid?
		assert @csy2 = course_starting_years(:tds_two)
		assert @csy2.valid?
    assert @teacher = users(:nicb)
    assert @topic = topics(:informatica_1)
    assert @at = activated_topics(:informatica_year_one)
 end

  def test_index
    #
    get :index, {}, { 'user' => @admin }
    assert_response :success
    #
    # lets get a a course
    #
    get :index, { :id => @course.id }, { 'user' => @admin }
    assert_response :success
    #
    # and a given starting year
    #
    y = @csy.starting_year
    get :index, { :id => @course.id, :year => y  }, { 'user' => @admin }
    assert_response :success
  end

	def test_new_activated_topic
    #
    ActivatedTopic.all.each { |at| at.destroy; assert at.frozen? }
    #
    assert_difference('ActivatedTopic.count') do
			xhr :get, :expand_new_topic, {:id => @course.id, :sy => @csy.starting_year}, { :user => @admin }
			assert_response :success
			xhr :post, :close_new_topic, {"commit"=>"Attiva", "bo"=>{"duration"=>"15",
        "semester_start"=>"5", "teacher_id"=> @teacher.id.to_s, "credits"=>"2", "topic_id"=> @topic.id.to_s},
        'activated_topic' => { 'course_starting_years' => { @csy.id.to_s => { 'status' => '1', 'teaching_typology' => 'C', 'mandatory_flag' => 'true' }}},
        :id => @csy.id}, { :user => @admin }
			assert_response :success
    end
    #
    # let's make sure the ActivatedTopic is exactly the one we're looking for
    # and it is a valid one...
    #
    assert at = ActivatedTopic.find_by_topic_id_and_teacher_id(@topic.id, @teacher.id)
    assert at.valid?
	end

  def test_auth_filtering
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

  #
  # FIXME: this test is to be rewritten after the bo controller has been
  # completely overhauled
  #
  class XhrAction
    attr_reader :action, :args, :method, :submit
    
    def initialize(a, p, m = :post, s = 'Attiva')
      @action = a
      @args = p
      @method = m
      @args.update('submit' => 'Attiva')
    end

		def regress
			true
		end

  end

  class CloseNewTopicAction < XhrAction
    
    def initialize(p, csy, m = :post, s = 'Attiva')
      full_params = add_activated_topics_params(p, csy)
      return super(:close_new_topic, full_params, m, s)
    end

  private

    def add_activated_topics_params(pars, csy)
      pars.update('activated_topic' => {})
      pars['activated_topic'].update('course_starting_years' => {})
      csys = CourseStartingYear.all
      csys.each do
        |gen_csy|
        csy_p = { gen_csy.id.to_s => { 'teaching_typology' => 'C', 'mandatory_flag' => 'true' }}
        csy_p[gen_csy.id.to_s].update('status' => '1') if gen_csy.id == csy.id
        pars['activated_topic']['course_starting_years'].update(csy_p)
      end
      return pars
    end

  end

	class CloseNewCourseAction < XhrAction

		attr_reader :initial_course_count

		def initialize(a, p, m = :post, s = 'Attiva')
			@initial_course_count = Course.count
			super
		end

		def regress
			Course.count == (self.initial_course_count + 1) ? true : false
		end

	end

	class ExpandNewYearAction < XhrAction

		def regress
			y = Time.now.year
			assert_select('option', y - 5)
			assert_select('option', y + 5)
			assert_select('option.selected', y)
			true
		end

	end

  test "AJAX actions" do
    tbt =
    [
      XhrAction.new(:expand_activated_topic, { :id => @at.id }),
      XhrAction.new(:expand_new_course, {}),
      XhrAction.new(:expand_new_topic, { :id => @course.id, :sy => @csy.starting_year }),
      XhrAction.new(:expand_new_year, { :id => @course.id }),
      XhrAction.new(:expand_teacher, { :id => @teacher.id }),
      XhrAction.new(:close_activated_topic, { :id => @at.id }),
      CloseNewCourseAction.new(:close_new_course, { :bo => { :name => 'Basic XXX', :duration => '42', :acronym => 'BX' }}),
      CloseNewTopicAction.new({ :bo => {"duration" => "20",
                                        "delivery_type" => "TF", "semester_start" => "1",
                                        "teacher_id" => @teacher.id, "credits"=>"3",
                                        "topic_id" => @topic.id }, :id => @csy.id }, @csy),
      XhrAction.new(:close_new_year, { :bo => { :year => CourseStartingYear.last(:order => 'starting_year').starting_year }, :id => @course.id }),
      XhrAction.new(:close_teacher, { :id => @teacher.id }),
    ]
    tbt.each do
      |test|
      CourseTopicRelation.delete_all # clean up the relations each time
      xhr test.method, test.action, test.args, { :user => @admin }
      assert_response :success, ":action => :#{test.action.to_s} failed"
			assert test.regress, "Regression failed for test \"#{test.action.to_s}\""
    end
  end

	test "expand new year should have the proper range of years" do
		xhr :post, :expand_new_year, { :id => @course.id }, { :user => @admin }
    assert_response :success, ":action => :#{:expand_new_year.to_s} failed"
		y = Time.now.year
		assert_select('option', { :text => (y - 5).to_s })
		assert_select('option', { :text => (y + 10).to_s })
		assert_select('[selected]', { :text => y.to_s })
	end

  test "activated topic expansion" do
    assert at = activated_topics(:an_old_course) # has 'Cpc' delivery type, which is known to be buggy
    assert at.valid?
    assert_equal 'CPc', at.delivery_type
    #
    post :expand_activated_topic, { :id => at.id }, { :user => @admin }
    assert_response :success
  end
  
  test "multiple courses get common lessons" do
    assert CourseTopicRelation.delete_all
    assert ActivatedTopic.delete_all
    assert_equal 0, ActivatedTopic.all.count
    assert_equal 0, CourseTopicRelation.all.count
    xhr :post, :close_new_topic, {"commit"=>"Attiva", "bo"=>{"duration"=>"15", "semester_start"=>"5", "teacher_id"=> @teacher.id.to_s, "credits"=>"2", "topic_id"=> @topic.id.to_s},
        'activated_topic' => { 'course_starting_years' => { 
	         @csy.id.to_s => { 'status' => '1', 'teaching_typology' => 'C', 'mandatory_flag' => 'true', 'course_year' => '2' },
	         @csy2.id.to_s => { 'status' => '1', 'teaching_typology' => 'C', 'mandatory_flag' => 'true', 'course_year' => '1' } }},
             :id => @csy.id}, { :user => @admin }
    assert_response :success
    assert_equal 1 , ActivatedTopic.all.count
    assert_equal 2, CourseTopicRelation.all.count
    assert_equal CourseTopicRelation.first.activated_topic_id, CourseTopicRelation.last.activated_topic_id
    assert_equal CourseTopicRelation.first.course_starting_year_id, @csy.id
    assert_equal CourseTopicRelation.last.course_starting_year_id, @csy2.id
  end

	test "expand new topic does not get outdated starting years" do
		#
		# first test that no outdated starting years appear in the form page
		#
		assert curr_aa = CourseStartingYear::CURRENT_AA
		assert sys = [ curr_aa - 2, curr_aa - 1, curr_aa ]
		sys.each do
			|sy|
    	assert ent = XhrAction.new(:expand_new_topic, { :id => @course.id, :sy => sy })
			xhr ent.method, ent.action, ent.args, { :user => @admin }
    	assert_response :success, ":action => :#{ent.action.to_s} failed"
			assert_select('table>tr>td', { :count => 0, :text => /Fuori Corso/ }, "Page should not contain any 'Fuori Corso' Course Starting Years while it does (starting year: #{sy}).")
		end
		#
		# now make sure that we have at least one for each regular current years
		#
		sys.each do
			|sy|
    	assert ent = XhrAction.new(:expand_new_topic, { :id => @course.id, :sy => sy })
			xhr ent.method, ent.action, ent.args, { :user => @admin }
    	assert_response :success, ":action => :#{ent.action.to_s} failed"
			['Primo Anno', 'Secondo Anno', 'Terzo Anno'].each do
				|year|
				assert_select('table>tr>td', { :minimum => 1, :text => /#{year}/ }, "Page should have at least one '#{year}' Course Starting Year while it does not (starting year: #{sy}).")
			end
		end
	end

end
