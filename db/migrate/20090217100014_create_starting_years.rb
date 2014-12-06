#
# $Id: 20090217100014_create_starting_years.rb 35 2009-02-25 23:12:53Z moro $
#
class CreateStartingYears < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
	    create_table :starting_years do |t|
        t.integer   :year, :null => false
	
	      t.timestamps
	    end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :starting_years
    end
  end
end
