#
# $Id: application_controller_test.rb 231 2010-03-02 21:34:38Z nicb $
#


require 'test/test_helper'

class ApplicationControllerTest < ActionController::TestCase

  test "svn revision method" do
    should_be = `svnversion -n`
    vstring = @controller.svn_revision
    assert_equal should_be, vstring
  end

end
