#
# $Id: topic.rb 290 2012-07-31 01:45:43Z nicb $
#

class Topic < ActiveRecord::Base

  has_many :activated_topics, :dependent => :destroy
  has_many :teachers, :through => :activated_topics

 # belongs_to :prerequisite, :class_name => 'TopicTitle'

  validates_presence_of :name, :acronym, :color
  validates_numericality_of :level, :allow_nil => true
	
	validates_length_of     :acronym,    :within => 2..7
  validates_uniqueness_of :name, :scope => :level
	validates_uniqueness_of	:acronym, :scope => :level
  COLOR_FORMAT_RE = /\A#[A-F0-9]{6}\Z/i
	validates_format_of :color, :with => COLOR_FORMAT_RE
	
	MAXIMUM_NAME_SIZE = 7	

	def display
		result = name.size > MAXIMUM_NAME_SIZE ? acronym : name
		result += (' ' + level.to_s) if level
		return result
	end

	def display_tooltip
    result = name
		result = name + ' ' + level.to_s if level
		return result
	end

	def acronym=(acro)
		write_attribute(:acronym, acro.upcase)
	end

  alias :full_name :display_tooltip

  class <<self

    def selection
      return all(:order => 'name, level').map { |t| [t.full_name, t.id] }
    end

  end

end
