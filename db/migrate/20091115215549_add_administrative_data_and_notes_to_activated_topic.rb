#
# $Id: 20091115215549_add_administrative_data_and_notes_to_activated_topic.rb 174 2009-11-16 22:08:01Z nicb $
#
class AddAdministrativeDataAndNotesToActivatedTopic < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :activated_topics, :hours_in_mo, :integer,   :null => false, :default => 0
      add_column :activated_topics, :hours_paid, :integer,    :null => false, :default => 0
      add_column :activated_topics, :teacher_gross, :decimal,   :null => false, :default => 0.00, :precision => 8, :scale => 2
      add_column :activated_topics, :teacher_net, :decimal,     :null => false, :default => 0.00, :precision => 8, :scale => 2
      add_column :activated_topics, :school_gross, :decimal,    :null => false, :default => 0.00, :precision => 8, :scale => 2

      add_column :activated_topics, :notes, :text
	  end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :activated_topics, :hours_in_mo
      remove_column :activated_topics, :hours_paid
      remove_column :activated_topics, :teacher_gross
      remove_column :activated_topics, :teacher_net
      remove_column :activated_topics, :school_gross

      remove_column :activated_topics, :notes
    end
  end
end
