#
# $Id: 20090122095939_create_lessons.rb 126 2009-10-30 03:22:06Z nicb $
#
class CreateLessons < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
	    create_table :lessons do |t|
        t.datetime :start_date, :null => false
        t.datetime :end_date, :null => false
        t.text     :description

        t.integer  :activated_topic_id, :null => false
	
	      t.timestamps
	    end
      add_index :lessons, :activated_topic_id
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :lessons
    end
  end
end
