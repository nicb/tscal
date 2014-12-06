class AddMoreFieldsToPlaceModel < ActiveRecord::Migration
  def self.up
		ActiveRecord::Base.transaction do
      add_column :places, :street, :string, :null => false, :default => ''
      add_column :places, :number, :string, :null => false, :default => ''
      add_column :places, :city, :string, :null => false, :default => ''
      add_column :places, :url, :string, :null => false, :default => 'http://maps.google.it/maps?f=q&source=s_q&hl=it&geocode=&q=padova&sll=45.419721,11.888237&sspn=0.027653,0.077162&ie=UTF8&hq=&hnear=Padova,+Veneto&ll=45.409568,11.876585&spn=0.006914,0.01929&t=h&z=16&iwloc=A'
			add_column :lessons, :place_id, :integer	

			add_index	:lessons, :place_id
    end
  end

  def self.down
		ActiveRecord::Base.transaction do
      remove_column :places, :street
      remove_column :places, :number
      remove_column :places, :city
      remove_column :places, :url
			remove_column	:lessons, :place_id
    end
  end
end
