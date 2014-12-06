#
# $Id: 20100221003400_move_base_courses_to_normal_courses.rb 223 2010-02-25 11:56:07Z nicb $
#
# This migrates all activated_topics from base courses into the usual courses
# This is an irreversible migration because we loose essential information in
# the process.
#
# We should eliminate side-effects from future classes
#
# This is required to let the migration use  the  Legacy  Objects  below
# without defaulting to the current (real) objects
#
ActiveRecord::Base.store_full_sti_class = false
#
module LegacyObjects

  class Lesson < ActiveRecord::Base
  end

  class ActivatedTopic < ActiveRecord::Base
    has_many :course_topic_relations, :dependent => :destroy
    has_many :course_starting_years, :through => :course_topic_relations
    has_many :lessons, :dependent => :destroy
  end

end


class MoveBaseCoursesToNormalCourses < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
			tbf_acros = [ 'TS', 'DS' ] # operate on three-year courses only
			tbfs = Course.find(:all, :conditions => ['acronym = ? or acronym = ?', tbf_acros[0], tbf_acros[1]])
			base = Course.find_by_name('Corsi Musicali di Base')
			base.course_starting_years.map do
			  |csy|
			  year = csy.starting_year
			  ats = csy.activated_topics
			  ats.each do
			    |at|
			    tbfs.each do
			      |tbf|
			      tcsys = tbf.course_starting_years.find(:all, :conditions => ["starting_year = ?", year])
			      tcsys.each do
              |tcsy|
              say_with_time("Moving #{at.topic.display} to #{tcsy.course.acronym} (#{tcsy.anno})") do
                tcsy.activated_topics << at 
                ctr = at.course_topic_relations.find(:first, :conditions => ['course_starting_year_id = ?', tcsy.id])
                ctr.update_attributes!(:teaching_typology => 'B')
              end
            end
			    end
          #
          # removing duplicate Activated Topics
          #
          dups = LegacyObjects::ActivatedTopic.find_all_by_topic_id_and_teacher_id(at.topic.id, at.teacher.id)
          if dups.size > 1
            dups.each do
              |dat|
              if dat.course_starting_years.size < tbf_acros.size
                say_with_time("Removing duplicate ActivatedTopic #{at.topic.display}") { dat.destroy }
              end
            end
          end
			  end
        say_with_time("Clearing course starting year for #{csy.course.name} (#{csy.anno})") { csy.destroy }
			end
      say_with_time("Clearing course #{base.name}") { base.destroy }
    end
  end

  def self.down
    raise(ActiveRecord::IrreversibleMigration, "This migration looses essential info and cannot be reversed")
  end
end
