#
# $Id: base.rb 201 2010-01-04 04:32:03Z nicb $
#

module Calendar

  module Display

    module Render

      class Base

        attr_reader :template, :object

        def initialize(t, o)
          @template = t
          @object = o
        end

      end

    end

  end

end
