#
# $Id: base.rb 201 2010-01-04 04:32:03Z nicb $
#
module Calendar

  module Column

	  #
	  # Column piles up a list of things
	  # types
	  #
	  class Base < Array
	    attr_reader :events
      attr_accessor :width

      def initialize(wid = 100) # 100 percent is the default width
        @width = wid
      end
	
	    def <<(el)
	      if el.is_a?(Array)
          el.each { |eel| super(eel) }
	      else
	        super(el)
	      end
	    end

	  end

  end

end
