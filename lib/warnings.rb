#
# $Id: warnings.rb 72 2009-08-28 15:15:53Z moro $
#
class Warnings
  attr_accessor :messages
  
  def initialize
    @messages = []
  end
  
  def <<(string)
    return messages << string
  end
  
  def full_messages
    return messages.join(', ')
  end
  
  def count
    return messages.size
  end
  
  def has_warnings?
    return !messages.empty?
  end
end