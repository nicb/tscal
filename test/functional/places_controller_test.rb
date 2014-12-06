#
# $Id: places_controller_test.rb 237 2010-03-08 11:10:50Z moro $
#
require 'test/test_helper'

class PlacesControllerTest < ActionController::TestCase

  fixtures :users

	def setup
		@newplace = "Arcella"
		@city = "Rimini"
		@street = "Via Napoli"
		@number = "22/c"
		@url = "http://www.rimi.it"
    @admin = users(:moro)
	end  

	test "should get index" do
    get :index, {}, { :user => @admin }
    assert_response :success
    assert_not_nil assigns(:places)
  end

  test "should get new" do
    get :new, {}, { :user => @admin }
    assert_response :success
  end

  test "should create place" do
    assert_difference('Place.count') do
      post :create, { :place => {:name => @newplace, :city => @city, :street => @street, :url => @url, :number => @number } }, { :user => @admin }
    end

    assert_redirected_to place_path(assigns(:place))
  end

  test "should show place" do
    get :show, { :id => places(:place_one).id }, { :user => @admin }
    assert_response :success
  end

  test "should get edit" do
    get :edit, { :id => places(:place_one).id }, { :user => @admin }
    assert_response :success
  end

  test "should update place" do
    put :update, { :id => places(:place_one).id, :place => { } }, { :user => @admin }
    assert_redirected_to place_path(assigns(:place))
  end

  test "should destroy place" do
    assert_difference('Place.count', -1) do
      delete :destroy, { :id => places(:place_one).id }, { :user => @admin }
    end

    assert_redirected_to places_path
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
