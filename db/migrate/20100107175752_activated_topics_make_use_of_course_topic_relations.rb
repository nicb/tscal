#
# $Id: 20100107175752_activated_topics_make_use_of_course_topic_relations.rb 223 2010-02-25 11:56:07Z nicb $
#
#
# this migration must do the following:
#
# - run through all ActivatedTopic(s) and create a CourseTopicRelation object
#   linking each AT to its CourseStartingYear, also setting the
#   teaching_typology field of the CTR with the value contained in
#   AT.teaching_typology
# - remove the "course_starting_year_id" field and its index in the AT
# - remove the "teaching_typology" field in the AT
#
# of course, the down method should reverse the operation
# 

#
# This is required to let the migration use  the  Legacy  Objects  below
# without defaulting to the current (real) objects
#
ActiveRecord::Base.store_full_sti_class = false

#
# the LegacyObjects are a bare representation of what the  objects  used
# to be before this migration (otherwise the migration won't work)
#
module LegacyObjects
  #
  # old-style ActivatedTopic
  #
  class ActivatedTopic < ActiveRecord::Base
    belongs_to :course_starting_year
    belongs_to :topic
  end

# #
# # old-style CourseStartingYear
# #
# class CourseStartingYear < ActiveRecord::Base
#   has_many :activated_topics
# end
end

class ActivatedTopicsMakeUseOfCourseTopicRelations < ActiveRecord::Migration

  class <<self
	  def up
      ActiveRecord::Base.transaction do
        create_course_topic_relations
      end
      ActiveRecord::Base.transaction do
        remove_column :activated_topics, :course_starting_year_id
        remove_column :activated_topics, :teaching_typology
      end
	  end
	
	  def down
      ActiveRecord::Base.transaction do
        add_column :activated_topics, :teaching_typology, :string, :limit => 4, :default => 'C', :null => false
        add_column :activated_topics, :course_starting_year_id, :integer
        add_index :activated_topics, :course_starting_year_id
        rebuild_legacy_associations
      end
	  end

  private

    def create_course_topic_relations
      LegacyObjects::ActivatedTopic.all.each do
        |at|
        csyid = ::CourseStartingYear.find(at.course_starting_year_id)
        ctr = ::CourseTopicRelation.create(:activated_topic_id => at.id,
                                         :course_starting_year => csyid,
                                         :teaching_typology => at.teaching_typology)
        raise(ActiveRecord::ActiveRecordError, "CourseTopicRelation(#{at.topic.name} #{at.topic.level}) is invalid (#{ctr.errors.full_messages.join(', ')})") unless ctr.valid?
      end
      raise(ActiveRecord::ActiveRecordError, "For some unknown reason no CourseTopicRelation records were created.") if CourseTopicRelation.all.blank?
    end

    def rebuild_legacy_associations
      CourseTopicRelation.all.each do
        |ctr|
        at = LegacyObjects::ActivatedTopic.find(ctr.activated_topic_id)
        at.update_attributes(:course_starting_year_id => ctr.course_starting_year_id,
                             :teaching_typology => at.teaching_typology)
        rel = at.save
        raise(ActiveRecord::ActiveRecordError, "Reverting back to Legacy ActivatedTopic failed (#{at.errors.full_messages.join(', ')})") unless rel
      end
    end

  end

end
