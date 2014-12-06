#
# $Id: option_group_helper.rb 138 2009-11-02 23:01:51Z nicb $
#

#
# this module sets the requirements for classes to be included inside an
# option_groups_from_collection_for_select selector tag. All methods have to
# be implemented by classes including this module or they'll get an exception
#
module OptionGroupHelper

  class MethodNotImplemented < ActiveRecord::ActiveRecordError
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def group
      return all.sort { |a, b| a.option_value <=> b.option_value }
    end

	  def group_label
	    raise(MethodNotImplemented)
	  end

  end

  def option_key
    return self.class.name + '.' + id.to_s
  end

  def option_value
    raise(MethodNotImplemented)
  end

  class FakeGroup

    attr_reader :label

    @@all_items = []

    def initialize(l)
      @label = l
      @@all_items << self
    end

    class <<self

      def group
        return @@all_items
      end

      def group_label
        return group[0].label
      end

      def clear
        @@all_items = []
      end

    end

    def option_key
      return label.gsub(/ /, '_')
    end

    def option_value
      return label
    end

  end

end
