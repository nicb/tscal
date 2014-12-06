#
# $Id: classrooms_controller_test.rb 118 2009-10-21 18:34:20Z nicb $
#
require 'test/test_helper'

class ClassroomsControllerTest < ActionController::TestCase

  fixtures :users

	def setup
		@place = Place.first
		@name = "aula 18"
    @admin = users(:moro)
	end

  test "should get index" do
    get :index, {}, { :user => @admin }
    assert_response :success
    assert_not_nil assigns(:classrooms)
  end

  test "should get new" do
    get :new, {}, { :user => @admin } 
    assert_response :success
  end

  test "should create classroom" do
    assert_difference('Classroom.count') do
      post :create, { :classroom => {:place => @place, :name => @name } }, { :user => @admin }
    end

    assert_redirected_to classroom_path(assigns(:classroom))
  end

  test "should show classroom" do
    get :show, { :id => classrooms(:class_one).id }, { :user => @admin }
    assert_response :success
  end

  test "should get edit" do
    get :edit, { :id => classrooms(:class_one).id }, { :user => @admin }
    assert_response :success
  end

  test "should update classroom" do
    put :update, { :id => classrooms(:class_one).id, :classroom => { } }, { :user => @admin }
    assert_redirected_to classroom_path(assigns(:classroom))
  end

  test "should destroy classroom" do
    assert_difference('Classroom.count', -1) do
      delete :destroy, { :id => classrooms(:class_one).id }, { :user => @admin }
    end

    assert_redirected_to classrooms_path
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
