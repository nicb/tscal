#
# $Id: courses_controller_test.rb 192 2009-12-14 22:49:48Z nicb $
#
require 'test/test_helper'

class CoursesControllerTest < ActionController::TestCase
  
  fixtures :users

	def setup
		@name = "Rails"
		@duration = 18
    @admin = users(:moro)
	end

	test "should get index" do
    get :index, {}, { :user => @admin }
    assert_response :success
    assert_not_nil assigns(:courses)
  end

  test "should get new" do
    get :new, {}, { :user => @admin }
    assert_response :success
  end

  test "should create course" do
    assert_difference('Course.count') do
      post :create, { :course => {:name => @name, :duration => @duration, :acronym => 'TST' } }, { :user => @admin }
    end

    assert_redirected_to course_path(assigns(:course))
  end

  test "should show course" do
    get :show, { :id => courses(:tds).id }, { :user => @admin }
    assert_response :success
  end

  test "should get edit" do
    get :edit, { :id => courses(:tds).id }, { :user => @admin }
    assert_response :success
  end

  test "should update course" do
    put :update, { :id => courses(:tds).id, :course => { } }, { :user => @admin }
    assert_redirected_to course_path(assigns(:course))
  end

  test "should destroy course" do
    assert_difference('Course.count', -1) do
      delete :destroy, { :id => courses(:tds).id }, { :user => @admin }
    end

    assert_redirected_to courses_path
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

end
