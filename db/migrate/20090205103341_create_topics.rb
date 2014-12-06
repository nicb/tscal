#
# $Id: 20090205103341_create_topics.rb 129 2009-10-30 13:34:35Z moro $
#
class CreateTopics < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
	    create_table :topics do |t|
        t.string    :name, :null => false
				t.string		:acronym, :null => false, :limit => 7
				t.string		:color, :null => false, :limit => 7
				t.integer		:level
				t.text			:description
	
	      t.timestamps
	    end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :topics
    end
  end

end
