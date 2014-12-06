#
# $Id$
#
class CreateUsers < ActiveRecord::Migration
  def self.up
		ActiveRecord::Base.transaction do
		  create_table :users do |t|
				t.string :login, :null => false
				t.string :first_name, :null => false
				t.string :last_name, :null => false
				t.string :email, :null => false
				t.string :url
				t.string :type, :null => false
				t.string :password, :null => false
		    t.timestamps
		  end
		end
  end

  def self.down
    drop_table :users
  end
end
