#
# $Id: 20100107002319_create_course_topic_relations.rb 212 2010-01-29 06:13:04Z nicb $
#
class CreateCourseTopicRelations < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
	    create_table :course_topic_relations do |t|
        t.integer :activated_topic_id,             :null => false
        t.integer :course_starting_year_id,        :null => false
        #
        # teaching_typology can be:
        # 'C' => 'Caratterizzante'
        # 'A' => 'Affini',
        # 'B' => 'Base',
        # 'Aa' => 'Altre Attivita`',
        #
	      t.string  :teaching_typology, :limit => 2, :null => false, :default => 'C'
        #
        # mandatory flag can be:
        # true  => 'Obbligatorio',
        # false => 'A Scelta'
        #
	      t.boolean :mandatory_flag,                 :null => false, :default => true
	    end
      add_index :course_topic_relations, :activated_topic_id
      add_index :course_topic_relations, :course_starting_year_id
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :course_topic_relations
    end
  end
end
