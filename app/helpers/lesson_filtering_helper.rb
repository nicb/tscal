#
# $Id: lesson_filtering_helper.rb 229 2010-03-01 21:13:47Z nicb $
#
# LessonFilteringHelpers helped ActiveRecords are records  that  can  be
# used as filters when setting up the calendar show
#
# All ActiveRecord::Base subclasses that need to be used as filters must
# include this module.
#
# The result is invariably a set of lessons (if any) which will then
# be used to generate the view
#
# all ActiveRecord::Base classes that include this module are supposed to have
# a has_many relationship with activated_topics
#

module LessonFilteringHelper

  class ClassDoesNotHaveActivatedTopics < ActiveRecord::ActiveRecordError; end
  #
  # generate_conditions
  # this is the default form. It can be overwritten if it needs to be
  # more complex than this
  #
  def generate_conditions
    raise(ClassDoesNotHaveActivatedTopics) unless respond_to?(:activated_topics)
    found = []
    activated_topics.each { |at| found << " (activated_topic_id = #{at.id}) " }
    #
    # if found.blank? then we need to generate a condition that is clearly
    # false
    #
    result = found.blank? ? '1 = 0' : '( ' + found.join(' or ') + ' )'
    return result
  end

  #
  # generate_query_hash(conditions) default implementation
  # this implementation can be over-ridden for more complex
  # queries (cf. for example Course implementation)
  #
  def generate_query_hash(conditions)
    return { :conditions => conditions }
  end

end
