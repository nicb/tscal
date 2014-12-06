#
# $Id: 20100105071508_remove_the_starting_year_model.rb 209 2010-01-07 00:15:18Z nicb $
#
# this migration must do the following:
#
# - change the course_starting_years table to add a field "starting_year_field"
#   (not to clash with existing methods)
# - move the starting_year data into that field from the starting_year_id
# - remove the "starting_year_id" field and its index
# - drop the "starting_year" record
# - rename 'starting_year_field' to 'starting_year'
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
  # make sure we have a StartingYear model
  #
  class StartingYear < ActiveRecord::Base
    has_many :course_starting_years
  end

  #
  # make sure we have a CourseStartingYear which has the proper associations
  # with StartingYear (even though they have disappeared in our current code)
  #
  class CourseStartingYear < ActiveRecord::Base
    belongs_to :starting_year
  end
end

class RemoveTheStartingYearModel < ActiveRecord::Migration

  class <<self
	  def up
      ActiveRecord::Base.transaction do
        add_column :course_starting_years, :starting_year_field, :integer, :limit => 4
        transfer_starting_year_to_field
        remove_index  :course_starting_years, :starting_year_id
        remove_column :course_starting_years, :starting_year_id
        rename_column :course_starting_years, :starting_year_field, :starting_year
        drop_table    :starting_years
      end
	  end
	
	  def down
      ActiveRecord::Base.transaction do
		    create_table :starting_years do |t|
	        t.integer   :year, :null => false
		
		      t.timestamps
		    end
        recreate_those_starting_years(2006, 2012)
      end
      raise(ActiveRecord::RecordNotFound) if LegacyObjects::StartingYear.all.blank?
      ActiveRecord::Base.transaction do
        rename_column :course_starting_years, :starting_year, :starting_year_field
        add_column :course_starting_years, :starting_year_id, :integer
        add_index :course_starting_years, :starting_year_id
        transfer_starting_year_to_starting_year_id
        remove_column :course_starting_years, :starting_year_field
      end
	  end

  private

    def transfer_starting_year_to_field
      csys = LegacyObjects::CourseStartingYear.all
      csys.each do
        |csy|
        csy.update_attribute(:starting_year_field, csy.starting_year.year)
        ret = csy.save
        raise(ActiveRecord::ActiveRecordError, "migration failed for course #{csy.name} (#{csy.starting_year.year})") unless ret
      end
    end

    def transfer_starting_year_to_starting_year_id
      csys = LegacyObjects::CourseStartingYear.all
      csys.each do
        |csy|
        sy = LegacyObjects::StartingYear.find_by_year(csy.read_attribute(:starting_year_field))
        raise(ActiveRecord::RecordNotFound, "StartingYear.find_by_year(#{csy.read_attribute(:starting_year_field)}) not found") unless sy
        csy.update_attribute(:starting_year_id, sy.id)
        ret = csy.save
        raise(ActiveRecord::ActiveRecordError, "rollback failed for course #{csy.name} (#{sy.year})") unless ret
      end
    end

    def recreate_those_starting_years(sy, ey)
      sy.upto(ey) { |n|  LegacyObjects::StartingYear.create(:year => n) }
    end

  end

end
