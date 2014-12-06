#
# $Id: 20090303110115_create_classrooms.rb 38 2009-03-03 12:12:39Z moro $
#
class CreateClassrooms < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :classrooms do |t|
	t.string :name, :null => false #("aula 4", "auditorium")
	t.integer :place_id, :null => false
	t.timestamps
      end
    end
  end

  def self.down
    drop_table :classrooms
  end
end
