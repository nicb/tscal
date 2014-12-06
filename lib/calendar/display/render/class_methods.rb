#
# $Id: class_methods.rb 201 2010-01-04 04:32:03Z nicb $
#

#
# this module sets the requirements for classes to be included inside an
# option_groups_from_collection_for_select selector tag. All methods have to
# be implemented by classes including this module or they'll get an exception
#
module Calendar

  module Display

    module Render
        
      def self.included(base)
        base.extend ClassMethods
      end

		  module ClassMethods

        class UnrecognizedRendererOption < ArgumentError; end

        #
        # this should be overridden by classes
        #
        DEFAULT_CALENDAR_TEMPLATE_PATH = 'calendar'
        def calendar_template_path
          return DEFAULT_CALENDAR_TEMPLATE_PATH
        end
		
        def has_renderer(options = {})
          rcn = options.has_key?(:class_name) ? options.delete(:class_name) : (name.demodulize.to_s + 'Renderer')
          tp = options.has_key?(:template_path) ? options.delete(:template_path) : calendar_template_path
          tfn = options.has_key?(:template) ? options.delete(:template) : name.demodulize.underscore
          tn = tp + '/' + tfn
          raise(UnrecognizedRendererOption, "Unrecognized option(s) \"#{options.keys.map { |k| k.to_s }.join(', ')}\" for has_renderer") unless options.keys.blank?
          tc = rcn.underscore.upcase
          addition = <<-EOF
            class #{rcn} < Calendar::Display::Render::Base
              #{tc} = '#{tn}'
              def initialize(obj)
                return super(#{tc}, obj)
              end
            end
            def prepare_rendering; return self; end
            def renderer
              robj = prepare_rendering
              return #{rcn}.new(robj)
            end
          EOF
          class_eval(addition)
        end
		
		  end

    end

  end

end
