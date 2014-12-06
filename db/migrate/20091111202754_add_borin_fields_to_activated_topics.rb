#
# $Id: 20091111202754_add_borin_fields_to_activated_topics.rb 164 2009-11-11 22:02:04Z nicb $
#
class AddBorinFieldsToActivatedTopics < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :activated_topics, :teaching_typology, :string, :limit => 4,
                 :null => false, :default => 'C'
      add_column :activated_topics, :delivery_type, :string, :limit => 4,
                 :null => false, :default => 'TF'
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :activated_topics, :teaching_typology
      remove_column :activated_topics, :delivery_type
    end
  end
end
