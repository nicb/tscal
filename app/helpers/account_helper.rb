#
# $Id: account_helper.rb 107 2009-10-18 21:38:37Z nicb $
#
module AccountHelper

  def check_authorization
    u = session['user']
    redirect_to(:controller => :account, :action => :login) unless u && u.authorized?
  end

end
