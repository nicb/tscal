#
# $Id: place.rb 237 2010-03-08 11:10:50Z moro $
#
class Place < ActiveRecord::Base

  has_many :lessons

  validates_presence_of :street, :number, :city, :name
	validates_uniqueness_of :number, :scope => :street

end
