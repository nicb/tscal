#
# $Id: account_controller.rb 253 2010-08-28 21:16:10Z nicb $
#
class AccountController < ApplicationController

  layout  'scaffold'

  skip_before_filter :login_required, :only => [ :login, :signup, :logout ]

  def login
    case request.method
      when :post
        if session['user'] = User.authenticate(params[:user][:login], params[:user][:password])
          if authorize?(session['user'])
            redirect_back_or_default :controller => :bo, :action => :index
          else
            reset_session
            redirect_to :controller => :calendar, :action => :show_js
          end
        else
          flash['notice'] = "Login \"#{params[:user][:login]}\" fallito"
          redirect_back_or_default '/'
      end
    end
  end
  
  #
  # signup - by default, anybody signing up is a teacher
  #
  def signup
    case request.method
      when :post
        @user = Teacher.new(params['user'])
        
        if @user.save      
          session['user'] = Teacher.authenticate(@user.login, params['user']['password'])
          flash['notice']  = "Signup successful"
          redirect_back_or_default :action => :login
        else
          redirect_to :action => :signup
        end
      when :get
        @user = Teacher.new
		end
  end  
  
  def delete
    if params['id'] and session['user']
      user = User.find(params['id'])
      user.destroy
    end
    redirect_back_or_default :action => "welcome"
  end  
    
  def logout
    reset_session
    redirect_to(:controller => :calendar, :action => :show_js)
  end
    
  def welcome
  end
  
end
