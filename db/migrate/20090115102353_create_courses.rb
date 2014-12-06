#
# $Id: 20090115102353_create_courses.rb 125 2009-10-30 01:58:27Z moro $
#
class CreateCourses < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
	    create_table :courses do |t|
	      t.string    :name, :null => false
				t.string		:acronym, :null => false, :limit => 5
	      t.integer   :duration, :null => false
	      t.timestamps
	    end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :courses
    end
  end
end
