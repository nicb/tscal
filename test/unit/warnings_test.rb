#
# $Id: warnings_test.rb 83 2009-09-09 02:58:51Z nicb $
#
require 'test/test_helper'

class WarningsTest < ActiveSupport::TestCase
  
  def test_messages_insertion
    msg1 = "Questo è un errore abbastanza generico"
    msg2 = "Questo si chiama gino, è un pò meno generico ma non dice comunque niente"
    assert w = Warnings.new
    assert !w.has_warnings?
    assert_equal 0, w.count
    assert w << msg1
    assert w.has_warnings?
    assert_equal 1, w.count
    assert w << msg2
    assert w.has_warnings?
    assert_equal 2, w.count
    assert_equal msg1, w.messages[0]
    assert_equal msg2, w.messages[1]
    assert_equal [msg1, msg2].join(', '), w.full_messages
  end
  
end
