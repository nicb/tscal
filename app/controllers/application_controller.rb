#
# $Id: application_controller.rb 224 2010-02-26 17:43:15Z mtisi $
#
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency 'login_system'
require_dependency 'datetime'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time (does this work?)

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '2b7b154eba7dcce82cf0b7da33f09f50'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  #
  # always check for authorization of user
  #
  include LoginSystem

  before_filter :login_required

  def authorize?(user) # cf. lib/login_system.rb => authorize?
    return user.is_a?(Admin) # currently authorize only Admin users
  end
  # def access_denied
  #   redirect_to :controller => :calendar, :action => :show
  # end
	def svn_revision
    unless @svn_revision
      tag = `basename $(grep '\/tags\/' #{RAILS_ROOT}/.svn/entries || echo none)`
      ver = `svnversion -n .`
      if tag == "none\n"
        @svn_revision = ver
      else
        @svn_revision = tag + ' (' + ver + ')'
      end
    end
    @svn_revision
  end
  
  def redirect_back(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

end
