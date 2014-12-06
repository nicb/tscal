#
# $Id: application_helper.rb 224 2010-02-26 17:43:15Z mtisi $
#
# Methods added to this helper will be available to all templates in the application.
#

module ApplicationHelper

  def auth_link_to(name, options = {}, html_options = {})
    session['return-to'] = options if options.is_a?(String)
    link_to(name, options, html_options)
  end

  def get_link_to_back(args)
    back_link = session[:return_to]
    session[:return_to] = nil
    back_link.nil? ? args : back_link
  end

end
