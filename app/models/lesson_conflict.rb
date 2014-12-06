#
# $Id: lesson_conflict.rb 220 2010-02-23 05:13:35Z nicb $
#
class LessonConflict < ActiveRecord::Base

  belongs_to :left_lesson, :class_name => 'Lesson'
  belongs_to :right_lesson, :class_name => 'Lesson'

end
