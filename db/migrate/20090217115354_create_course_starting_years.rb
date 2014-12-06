#
# $Id: 20090217115354_create_course_starting_years.rb 105 2009-10-15 22:30:50Z moro $
#
class CreateCourseStartingYears < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :course_starting_years do |t|
	t.integer :course_id, :null => false
	t.integer	:starting_year_id, :null => false
	t.string	:color, :null => false, :limit => 7
      end
      add_index :course_starting_years, :course_id
      add_index :course_starting_years, :starting_year_id
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :course_starting_years
    end
  end
end
