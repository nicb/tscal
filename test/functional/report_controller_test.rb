#
# $Id: report_controller_test.rb 298 2012-11-03 14:34:29Z nicb $
#
require 'test/test_helper'
require 'test/utilities/random'

class ReportControllerTest < ActionController::TestCase

  fixtures :course_starting_years, :activated_topics, :course_topic_relations

  def setup
    assert @at = activated_topics(:informatica_year_one)
    assert @at.valid?
		assert !@at.course_topic_relations.blank?
    assert !@at.course_starting_years.blank?
		assert @at_old = activated_topics(:informatica_year_three)
		assert !@at_old.course_topic_relations.blank?
    assert !@at_old.course_starting_years.blank?
  end

  def test_root
    assert_generates '/report', { :controller => 'report', :action => 'index' }
    assert_recognizes({ :controller => 'report', :action => 'index' }, '/report')
    assert_routing({ :method => :get, :path => '/report' }, { :controller => 'report', :action => 'index' })
    get :index
    assert_response :success
    assert_template :index
  end

  def test_index
    assert_generates '/report', { :controller => 'report', :action => 'index' }
    assert_recognizes({ :controller => 'report', :action => 'index' }, '/report/index')
    assert_routing({ :method => :get, :path => '/report' }, { :controller => 'report', :action => 'index' })
    get :index
    assert_response :success
    assert_template :index
  end

  test "show_filtered_by_xx" do
		assert random_environment(@at.teacher, { :num_topics => 2, :num_courses => 2, :num_lessons => 3 })
		ActivatedTopic.all.each do
			|at|
	    shows =
	    {
	      'delivery_type' => { :index => at.delivery_type, :content => at.delivery_type, :div_class => 'delivery_type' },
	      'activation' => { :index => at.activity_report, :content =>  at.activity_report, :div_class => 'activity_report' },
        'year' =>  at.course_starting_years(true).map { |csy| { :index => csy.roman_year, :content => at.all_roman_years, :div_class => 'year' } },
	      'semester' => [ { :index => '1sem', :content => at.first_semester, :div_class => 'first_semester' },
	                      { :index => '2sem', :content => at.second_semester, :div_class => 'second_semester' } ],
        'course' => at.course_starting_years(true).map { |csy| { :index => csy.course.id, :content => csy.course.acronym, :div_class => 'course_acronym' } },
	      'teacher' => { :index => at.teacher.id, :content =>  at.teacher.full_name, :div_class => 'teacher_' + at.teacher.teacher_typology },
	      'teaching_typology' => at.course_topic_relations(true).map { |ctr| { :index =>  ctr.teaching_typology, :div_class => 'teaching_typology' } },
	      'teacher_typology' => { :index => at.teacher.teacher_typology, :div_class => 'teacher_typology_' + at.teacher.teacher_typology },
	    }
	    test_no = 0
	    shows.each do
	      |k, v|
	      meth = 'show_filtered_by_' + k
		    path = meth + '_path'
	      tests = v.is_a?(Array) ? v : [ v ]
	      tests.each do
	        |vv|
	        test_no += 1
		      sval = vv[:index].to_s
		      div_class = vv[:div_class]
		      content = vv.has_key?(:content) ? vv[:content] : vv[:index].to_s
		      assert_generates('/report/' + sval + '/' + meth, { :controller => 'report', :action => meth, :id => sval })
		      assert_recognizes({ :controller => 'report', :action => meth, :id => sval }, '/report/' + sval + '/' + meth)
		      get meth.intern, { :id => sval }
		      assert_response :success
		      assert_template :index
		      assert assigns(:activated_topics)
		      assert assigns((k.to_s + '_selector').intern)
 	        assert_select("td.#{div_class}", /#{content}/, "Test n.#{test_no}: no div.#{div_class} exposes \"#{content}\" text")
					assert_select("td.#{div_class}", { :count => 0, :text => '' }, "Test n.#{test_no}: td.#{div_class} found to be empty while setting #{k} to #{sval} using method #{meth}")
				  assert_select("td.year", { :count => 0, :text => /FC/ }, "Test n.#{test_no}: FC year found when setting #{k} to #{sval} using method #{meth}")
				  assert_select("td.year", { :count => 0, :text => '' }, "Test n.#{test_no}: Year field found empty when setting #{k} to #{sval} using method #{meth}")
				  assert_select("td.year", { :minimum => 1, :text => /I+/ }, "Test n.#{test_no}: No 'I' field found when setting #{k} to #{sval} using method #{meth}")
	      end
			end
    end
  end

  test "to make sure we do not get FC years displayed when filtering by xx" do
    shows =
    {
      'year' =>  { :index => @at.course_starting_years[0].roman_year, :content => @at.all_roman_years, :div_class => 'year' },
    }
    test_no = 0
    shows.each do
      |k, v|
      meth = 'show_filtered_by_' + k
	    path = meth + '_path'
      tests = v.is_a?(Array) ? v : [ v ]
      tests.each do
        |vv|
        test_no += 1
	      sval = vv[:index].to_s
	      div_class = vv[:div_class]
	      content = vv.has_key?(:content) ? vv[:content] : vv[:index].to_s
	      assert_generates('/report/' + sval + '/' + meth, { :controller => 'report', :action => meth, :id => sval })
	      assert_recognizes({ :controller => 'report', :action => meth, :id => sval }, '/report/' + sval + '/' + meth)
	      get meth.intern, { :id => sval }
	      assert_response :success
	      assert_template :index
	      assert assigns(:activated_topics)
	      assert assigns((k.to_s + '_selector').intern)
        assert_select("td.#{div_class}", { :count => 0, :text => 'FC' })
      end
    end
  end

  test "blank selectors" do
    shows = [ 'delivery_type', 'activation', 'year', 'semester', 'course', 'teacher',
      'teaching_typology', 'teacher_typology', ]
    shows.each do
      |m|
      meth = 'show_filtered_by_' + m
      path = '/report/-1/' + meth
      assert_generates path, { :controller => 'report', :action => meth, :id => '-1' }
      assert_recognizes({ :controller => 'report', :action => meth, :id => '-1' }, path)
      assert_routing({ :method => :get, :path => path }, { :controller => 'report', :action => meth, :id => '-1' })
      get meth.intern, { :id => '-1' }
	    assert_response :success
	    assert_template :index
	    assert ats = assigns(:activated_topics)
			assert !ats.empty?, "Got no ActivatedTopics for method \"#{meth}\""
			assert_select("td.year", { :count => 0, :text => /FC/ }, "FC year found when setting #{m} to -1")
			assert_select("td.year", { :count => 0, :text => '' }, "Year field found empty when setting #{m} to -1")
			['I', 'II', 'III'].each do
				|ry|
				assert_select("td.year", { :minimum => 1, :text => /#{ry}/ }, "No #{ry} field found when setting #{m} to -1")
			end
    end
  end

  def test_lessons
    assert_generates '/report/' + @at.id.to_s + '/lessons', { :controller => 'report', :action => 'lessons', :id => @at.id.to_s }
    assert_recognizes({ :controller => 'report', :action => 'lessons', :id => @at.id.to_s }, '/report/' + @at.id.to_s + '/lessons/' )
    assert_routing({ :method => :get, :path => '/report/' + @at.id.to_s + '/lessons' }, { :controller => 'report', :action => 'lessons', :id => @at.id.to_s })
    get :lessons, { :id => @at.id.to_s }
    assert_response :success
    assert_template :lessons
  end

  def test_teacher
    assert_generates '/report/' + @at.teacher.id.to_s + '/teacher', { :controller => 'report', :action => 'teacher', :id => @at.teacher.id.to_s }
    assert_recognizes({ :controller => 'report', :action => 'teacher', :id => @at.teacher.id.to_s }, '/report/' + @at.teacher.id.to_s + '/teacher/' )
    assert_routing({ :method => :get, :path => '/report/' + @at.teacher.id.to_s + '/teacher' }, { :controller => 'report', :action => 'teacher', :id => @at.teacher.id.to_s })
    get :teacher, { :id => @at.teacher.id.to_s }
    assert_response :success
    assert_template :teacher
  end

	test "no FC years are shown at all" do
		get :index
		assert_response :success
		assert_template :index
    assert_select("body", { :count => 0, :text => /FC/ })
	end

	test "no table fields are empty" do
		get :index
		assert_response :success
		assert_template :index
    assert_select('td.year', { :count => 0, :text => '' })
	end

private

	include Test::Utilities::RandomEnvironment

end
