#
# $Id: topics_controller_test.rb 290 2012-07-31 01:45:43Z nicb $
#
require 'test/test_helper'

class TopicsControllerTest < ActionController::TestCase

  fixtures :users, :topics

  def setup
    @admin = users(:moro)
    @topic = topics(:informatica_1)
  end

  test "should get index" do
    get :index, {}, { :user => @admin }
    assert_response :success
    assert_not_nil assigns(:topics)
  end

  test "should get new" do
    get :new, {}, { :user => @admin }
    assert_response :success
  end

  test "should create topic" do
    assert_difference('Topic.count') do
      post :create, { :topic => { :name => 'Aldous', :acronym => 'ALD', :color => '#ff00ff'} }, { :user => @admin }
    end

    assert_redirected_to topic_path(assigns(:topic))
  end

  test "should show topic" do
    get :show, { :id => @topic.id }, { :user => @admin }
    assert_response :success
  end

  test "should get edit" do
    get :edit, { :id => @topic.id }, { :user => @admin }
    assert_response :success
  end

  test "should update topic" do
    put :update, { :id => @topic.id, :topic => {  :name => 'Aldous' } }, { :user => @admin }
    assert_redirected_to topic_path(assigns(:topic))
  end

  test "should destroy topic" do
    assert_difference('Topic.count', -1) do
      delete :destroy, { :id => @topic.id }, { :user => @admin }
    end

    assert_redirected_to topics_path
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
