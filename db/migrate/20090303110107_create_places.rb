#
# $Id: 20090303110107_create_places.rb 99 2009-09-19 00:08:06Z moro $
#
class CreatePlaces < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
	create_table :places do |t|
	  t.string :name, :null => false #bertacchi, eremitani...
	  t.timestamps
	end
    end
  end

  def self.down
    drop_table :places
  end
end

