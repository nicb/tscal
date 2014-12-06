#
# $Id: 20111009033713_add_course_year_to_course_topic_relation.rb 290 2012-07-31 01:45:43Z nicb $
#
# this migration adds the course year of execution to the course/topic relation. Since there are
# many ctr records already in the database, we must figure out an algorithm to make
# it so that all old courses will get a course year anyway (even if it's
# wrong, something that should not matter since we're talking about old
# topics). 
#
# The algorithm is really a hack but I can't think of  anything  better,
# save copying all data by hand (something which I do not want  to  do).
# It works as follows:
#
# 1) if the topic has also a level, then it copies the level into the course year
# 2) if it doesn't, then it sets the course year to 1
#
# There's also another issue: this column should really be :null => false.
# However, if we do it that way right at the beginning, the migration will
# fail because the db will have many records with null fields. So we need to
# do the migration, then fill fields, then change the column to add the :null
# => false option.

class AddCourseYearToCourseTopicRelation < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      add_column :course_topic_relations, :course_year, :integer
    end
    ActiveRecord::Base.transaction do
      CourseTopicRelation.all.each do
        |ctr|
        t = ctr.activated_topic.topic
        if t.level
		      how_many = Topic.find_all_by_name(t.name).size
		      how_many_per_year = calculate_how_many_per_year(how_many)
		      adder = (t.level % how_many_per_year) == 0 ? 0 : 1
		      cy = (t.level / how_many_per_year).floor + adder
		      cy = cy > 3 ? 3 : cy
        else
          cy = 1
        end
		    say("Setting course-topic relation for topic \"#{t.full_name}\" for course #{ctr.course_starting_year.course.name} (#{how_many}: #{how_many_per_year}/y) to course year #{cy}")
        ctr.update_attributes!(:course_year => cy)
      end
    end
    #
    # now change the table to add the :null option and remove the default value
    #
    ActiveRecord::Base.transaction do
      change_column_null :course_topic_relations, :course_year, false
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :course_topic_relations, :course_year
    end
  end

private

  def self.calculate_how_many_per_year(count)
    res = case count.to_s
    when /[1-3]/ : 1
    when /[4-6]/ : 2
    when /[7-9]/ : 3
    when /[10-12]/ : 4
    else 1
    end
    res
  end

end
