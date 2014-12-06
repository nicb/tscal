#
# $Id: auth_test.rb 260 2010-08-31 15:30:39Z nicb $
#
require 'test/test_helper'

class AuthTest < ActionController::IntegrationTest
  fixtures :users

  def setup
    @admin_user = users(:moro)
    @non_admin_user = users(:nicb)
  end

  def test_authorization_in_out_and_again
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
      # now logout
      #
      sess.get url_for(:controller => :account, :action => :logout)
      sess.assert_redirected_to '/'
      assert_nil sess.session['user']
      #
      # now let us try to get to the bo controller index again
      # (this should fail and redirect to login)
      #
      sess.get url_for(:controller => :bo, :action => :index)
      sess.assert_redirected_to :controller => :account, :action => :login
    end
  end

  def test_kick_out_non_authorized_users
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
	    # first try to login with a wrong password (should go back to login)
	    #
	    sess.post url_for(:controller => :account, :action => :login), { :user => { :login => @non_admin_user.login, :password => 'wrong_password' } }
	    assert_response :success
	    assert_template 'account/login.html.erb'
	    #
	    # actually login with the right password (should go back to calendar)
	    #
	    sess.post url_for(:controller => :account, :action => :login), { :user => { :login => @non_admin_user.login, :password => 'test' } }
      sess.assert_redirected_to '/'
      assert_nil sess.session['user']
	    #
	    # next time should be redirected to login again
	    #
	    sess.get url_for(:controller => :bo, :action => :index)
      sess.assert_redirected_to :controller => :account, :action => :login
    end
  end
end
