#
# $Id$
#
require File.dirname(__FILE__) + '/../test_helper'

# Raise errors beyond the default web-based presentation
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < ActionController::TestCase

  fixtures :users
  
  def setup
    @user = users(:moro)
    @controller = AccountController.new
  end
  
  test "login page" do
    get :login
	  assert_response :success
  end

  test "successeful login with return_to" do
    assert session['return-to'] = "/bogus/location"

    post :login, :user => { "login" => @user.login, "password" => "test" }
    assert session["user"]

    assert_equal @user, session["user"]
    
    assert_redirected_to "/bogus/location"
  end

  test "successeful login with default" do
    assert_nil session['return-to'] = nil

    post :login, :user => { "login" => @user.login, "password" => "test" }
    assert session["user"]

    assert_equal @user, session["user"]
    
    assert_redirected_to :controller => :bo, :action => :index
  end

  test "failing login" do
    #
    # test once with standard return-to
    #
    session['return-to'] = '/account/login'
    post :login, :user => { "login" => 'fail', "password" => "fail" }
    assert_nil session["user"]

    assert_redirected_to :controller => :account, :action => :login
    #
    # test a second time with non-standard return-to
    #
    session['return-to'] = '/bogus/location'
    post :login, :user => { "login" => 'fail', "password" => "fail" }
    assert_nil session["user"]

    assert_redirected_to '/bogus/location'
  end
  
  test "signup" do
    loc = "/bogus/location"
    session['return-to'] = loc
    post :signup, "user" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "newpassword",
                              :last_name => 'New', :first_name => 'Bob', :email => 'newbob@nowhere.com'}
    assert session["user"]
    assert_redirected_to loc
  end

  def test_bad_signup
    @request.session['return-to'] = "/bogus/location"

    post :signup, "user" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "wrong",
                              :last_name => 'New', :first_name => 'Bob', :email => 'newbob@nowhere.com'}
    assert !User.find_by_login('newbob')
    assert_redirected_to :controller => :account, :action => :signup

    # 
    # not enough data
    #
    post :signup, "user" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "newpassword" }
    assert !User.find_by_login('yo')
    assert_redirected_to :controller => :account, :action => :signup

    post :signup, "user" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "wrong",
                              :last_name => 'New', :first_name => 'Bob', :email => 'newbob@nowhere.com'}
    assert !User.find_by_login('yo')
    assert_redirected_to :controller => :account, :action => :signup
  end

# def test_invalid_login
#   session['return-to'] = '/account/login'
#   post :login, :user => { :login => "moro", :password => "not_correct" }
#    
#   assert !session['user']
#   assert_response :redirect
#   assert_template :login
#   
# end
  
  def test_logon_logoff

    post :login, :user => { "login" => @user.login, "password" => "test" }
    assert session['user']
    assert_redirected_to :controller => :bo, :action => :index 

    get :logout, {}, { :user => @user }
    assert !session['user']
#    assert_redirected_to :controller => :calendar, :action => :show
    assert_redirected_to '/'

  end
  
  def test_auth_filtering
    #
    # try getting the login pages without authorization
    #
    get :login
    assert_response :success
    get :signup
    assert_response :success
  end

end
