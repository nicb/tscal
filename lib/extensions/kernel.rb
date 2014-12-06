#
# $Id: kernel.rb 127 2009-10-30 03:23:06Z nicb $
#
module Kernel

private

  def method_name # will be superseded by __method__ in ruby 1.9
    caller[0] =~ /`([^']*)'/ and $1
  end

end
