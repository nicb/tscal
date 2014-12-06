#
# $Id: 20100221031636_create_lesson_conflicts.rb 220 2010-02-23 05:13:35Z nicb $
#
class CreateLessonConflicts < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
	    create_table :lesson_conflicts do |t|
        t.integer :left_lesson_id	
        t.integer :right_lesson_id	
	    end
      add_index :lesson_conflicts, :left_lesson_id
      add_index :lesson_conflicts, :right_lesson_id
    end
    #
    # now rebuild all already existing conflicts
    #
    say_with_time("Rebuilding conflicts table...") do
      ActiveRecord::Base.transaction do
        Lesson.all.each { |l| l.save_conflicts }
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :lesson_conflicts
    end
  end
end
