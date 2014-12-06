#
# $Id: 20090827093516_create_blacklisted_dates.rb 87 2009-09-13 14:03:55Z nicb $
#

class CreateBlacklistedDates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :blacklisted_dates do |t|
				t.datetime :blacklisted, :null => false, :unique => true
				t.string :description, :limit => 4096, :default => "Il conservatorio è chiuso"
				t.timestamps
      end
    end
  end

  def self.down
    drop_table :blacklisted_dates
  end
end
