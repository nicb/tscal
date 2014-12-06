#
# $Id: calendarable.rb 290 2012-07-31 01:45:43Z nicb $
#
# Calendarable items have to implement a few methods and they they can all be
# included in the calendar display. In order to make sure these elements are
# implemented we raise exceptions. A method is for free: find_overlaps().

require 'extensions/kernel'

module Calendarable

	attr_reader :end_date_lock

  class MethodNotImplemented < ActiveRecord::ActiveRecordError
  end

private

  def pure_virtual(m)
    self.class.pure_virtual(m)
  end

public
  #
  # start_date must be the starting date of an event
  #

  def start_date
    pure_virtual(method_name)
  end

  #
  # since ed is calculated on the fly following a virtual attribute like 
  # duration, care must be taken when setting the start date, because there
  # could be a race condition when both duration and start_date are updated at
  # the same time: if the duration is updated +first+ and the start_date
  # afterwards, the ed may result in being completely wrong. Thus, when
  # setting the start date the duration is always preserved. This needs to be
	# done *only* if the +duration+ is bigger than 0, otherwise it means that
	# the +end_date+ is still to be set, and thus the duration is invalid
	# anyway.
  #

  #
  # raw_start_date= must be implemented in the receiver object
  #
  def raw_start_date=(d)
    pure_virtual(method_name)
  end

  def start_date=(d)
		maybe_dur = self.duration
    current_dur = maybe_dur if maybe_dur > 0
    self.raw_start_date = d
    self.duration=(current_dur) if current_dur
  end

  #
  # end_date must be the ending date of an event
  #
  def end_date
    pure_virtual(method_name)
  end

  #
  # duration methods. The duration is a fixnum in minutes
  #
  def duration
    result = self.start_date && self.end_date ? ((self.end_date - self.start_date)/60.0).round : 0
    return result
  end

  def duration=(mins)
    m = mins.to_i # make sure it is an integer
    self.end_date = start_date.since(m.minutes)
    return m
  end

protected

  def handle_duration_arg(parms)
		unlock_end_date
    args = parms.dup
    dur =  args.has_key?(:duration) ? args.delete(:duration) : 0
    args[:end_date] = args[:start_date].since(dur.to_i.minutes) if args.has_key?(:start_date) && !args.has_key?(:end_date)
		lock_end_date
    return args
  end

public
  #
  # display is the ability of displaying myself
  #
  def topic_display
    pure_virtual(method_name)
  end

  def topic_display_tooltip
    pure_virtual(method_name)
  end

  def course_display
    pure_virtual(method_name)
  end

  def course_display_tooltip
    pure_virtual(method_name)
  end

  #
  # class methods
  #

	def self.included(base)
		base.extend ClassMethods
	end

  module ClassMethods

    def pure_virtual(m)
      raise(MethodNotImplemented, m)
    end

    def filtered(tstart, tend, filter = nil)
      pure_virtual(self.class.name + '::' + method_name)
    end

    def manage_filter(filter)
      pure_virtual(method_name)
    end

  end

  class OverlapCondition
    attr_reader :b1, :b2, :c1, :c2

    def initialize(bool1, bool2, cond1, cond2)
      (@b1, @b2, @c1, @c2) = [ bool1, bool2, cond1, cond2 ]
    end

    def condition_string
      return "(start_date #{b1} ? and end_date #{b2} ?)"
    end

  end

private

  def overlap_conditions
    ocs =
    [
      OverlapCondition.new('<=', '>',  start_date, start_date),
      OverlapCondition.new('<',  '>=', end_date, end_date),
      OverlapCondition.new('>=', '<=', start_date, end_date),
      OverlapCondition.new('<=', '>=', start_date, end_date),
    ]
    return ocs
  end

public

  def overlaps?(other)
    result = false
    result = true if ((other.start_date <= start_date and other.end_date > start_date) or (other.start_date < end_date and other.end_date >= end_date) or (other.start_date >= start_date and other.end_date <= end_date) or (other.start_date <= start_date  and other.end_date >= end_date))
    return result
  end

  def find_overlaps(filter = nil)
    sd = start_date.dup
    ed = end_date.dup
    cs = "((start_date <= ? and end_date > ?) or (start_date < ? and end_date >= ?) or (start_date >= ? and end_date <= ?) or (start_date <= ?  and end_date >= ?))"
    mfilt = self.class.manage_filter(filter)
    cs += " and (#{mfilt})" unless mfilt.blank?
    conditions = [ cs, sd, sd, ed, ed, sd, ed, sd, ed ]
    return self.class.all(:conditions => conditions, :order => 'start_date, end_date')
  end

	#
	# required to avoid race conditions when writing dates
	#
	def lock_end_date
		@end_date_lock = true
	end
  
	def unlock_end_date
		@end_date_lock = false
	end

	def end_date_locked?
		self.end_date_lock
	end

	def attributes=(new_attrs = nil, protect_protected = true)
		new_attrs.stringify_keys!
		self.unlock_end_date if new_attrs.has_key?('end_date')
		res = super
		self.lock_end_date
	end
  
end
