#
# $Id: lessons_controller.rb 193 2009-12-15 00:59:04Z nicb $
#

module At

  class LessonsController < ApplicationController

    layout 'activated_topics'

    # DELETE /at/lessons/:id/remove(.:format)
    def remove
		  render(:partial => 'remove', :locals => {:div_index => params[:id]})
    end

  end

end
