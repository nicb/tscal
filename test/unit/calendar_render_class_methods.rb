#
# $Id: calendar_render_class_methods.rb 201 2010-01-04 04:32:03Z nicb $
#

require 'test/test_helper'
require 'calendar'

class CalendarRenderClassMethodsTest < ActiveSupport::TestCase

  test "standard default renderer addition" do
	  class TestEvent
	    include Calendar::Display::Render
	    has_renderer
	  end
    assert defined?(TestEvent::TestEventRenderer)
    assert te = TestEvent.new
    assert te.respond_to?(:renderer)
    assert_equal TestEvent::TestEventRenderer, te.renderer.class
    assert_equal TestEvent, te.renderer.object.class
    assert te.renderer.respond_to?(:template)
    assert_equal Calendar::Display::Render::ClassMethods::DEFAULT_CALENDAR_TEMPLATE_PATH + '/test_event', te.renderer.template
  end

  test "renderer addition with arguments" do
	  class TestEvent
	    include Calendar::Display::Render
	    has_renderer :template_path => 'something/else', :template => 'another', :class_name => 'AnotherRenderer'
	  end
    assert defined?(TestEvent::AnotherRenderer)
    assert te = TestEvent.new
    assert te.respond_to?(:renderer)
    assert_equal TestEvent::AnotherRenderer, te.renderer.class
    assert_equal TestEvent, te.renderer.object.class
    assert te.renderer.respond_to?(:template)
    assert_equal 'something/else/another', te.renderer.template
  end

  test "renderer addition with wrong arguments" do
    assert_raise(Calendar::Display::Render::ClassMethods::UnrecognizedRendererOption) do
		  class TestEvent
		    include Calendar::Display::Render
		    has_renderer :wrong_argument_1 => 'wrong', :wrong_argument_2 => 'wrong!'
		  end
    end
  end
end
