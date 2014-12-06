#
# $Id: 20090217100909_create_activated_topics.rb 191 2009-11-25 09:30:42Z moro $
#
class CreateActivatedTopics < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
	    create_table :activated_topics do |t|
        t.integer		:topic_id, :null => false
        t.integer		:teacher_id, :null => false
				t.integer		:course_starting_year_id, :null => false
        t.integer		:credits, :null => false
        t.integer		:duration, :null => false ### in ore###
        t.integer		:semester_start, :null => false
        t.integer		:prerequisite_id
	
	      t.timestamps
	    end
      add_index :activated_topics, :topic_id
      add_index :activated_topics, :teacher_id
      add_index :activated_topics, :course_starting_year_id
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :activated_topics
    end
  end
end
