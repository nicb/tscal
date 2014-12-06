#
# $Id: 20091111220454_add_typology_to_teachers.rb 165 2009-11-11 22:33:47Z nicb $
#
class AddTypologyToTeachers < ActiveRecord::Migration
  def self.up
		ActiveRecord::Base.transaction do
      add_column :users, :teacher_typology, :string, :limit => 1, :null => false, :default => 'I'
    end
  end

  def self.down
		ActiveRecord::Base.transaction do
      remove_column :users, :teacher_typology
    end
  end
end
