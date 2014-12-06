#
# $Id: classroom.rb 39 2009-03-03 15:01:00Z moro $
#
class Classroom < ActiveRecord::Base
  
   belongs_to :place

   validates_presence_of :name
   validates_presence_of :place_id

   validates_uniqueness_of :name, :scope => :place_id
end
