#
# $Id: lesson_conflict_test.rb 272 2011-07-07 01:43:58Z mgiulio $
#
require 'test/test_helper'

class LessonConflictTest < ActiveSupport::TestCase

  fixtures :activated_topics

  def setup
    assert @at1 = activated_topics(:informatica_year_one)
    assert @at1.valid?
    assert @at2 = activated_topics(:pianoforte_year_one)
    assert @at2.valid?
    assert @sd = Time.zone.local(2010, 2, 15, 9, 0)
    assert @dur = 120
    count = 0
    @at1.course_starting_years.each do 
    	|csy1|
    	@at2.course_starting_years.each do
    		|csy2|
    		count +=1 if csy1 == csy2
    	end
    end
    assert count > 0
    LessonConflict.delete_all
    Lesson.delete_all
    end

  # Replace this with your real tests.
  test "create" do
   
    #
    # we create two conflicting lessons, we should have one intermediate
    # LessonConflict record
    #
    assert cl1 = Lesson.create(:activated_topic => @at1, :start_date => @sd, :duration => @dur)
    assert cl1.valid?
    assert_equal 0, LessonConflict.count
    assert cl2 = Lesson.create(:activated_topic => @at2, :start_date => @sd, :duration => @dur)
    assert cl2.valid?
    assert_equal 1, LessonConflict.count
    assert_equal false, cl1.verify_compatibility
    assert_equal false, cl2.verify_compatibility
    assert_equal [ cl2 ], cl1.conflicts
    assert_equal [ cl1 ], cl2.conflicts
  end

  test "destroy" do
    #
    # we create two conflicting lessons, we should have one intermediate
    # LessonConflict record, and we destroy them in turn
    #
    assert cl1 = Lesson.create(:activated_topic => @at1, :start_date => @sd, :duration => @dur)
    assert cl1.valid?
    assert_equal 0, LessonConflict.count
    assert cl2 = Lesson.create(:activated_topic => @at2, :start_date => @sd, :duration => @dur)
    assert cl2.valid?
    assert_equal 1, LessonConflict.count
    #
    # now we destroy one of them
    #
    assert cl1.destroy
    assert cl1.frozen?
    assert_equal 0, LessonConflict.count
    assert_equal [ ], cl2.conflicts
    assert_equal true, cl2.verify_compatibility
    #
    # now let's do it again destroying the other one
    #
    assert cl1 = Lesson.create(:activated_topic => @at1, :start_date => @sd, :duration => @dur)
    assert cl1.valid?
    assert_equal 1, LessonConflict.count
    #
    # now we destroy the other one
    #
    assert cl2.destroy
    assert cl2.frozen?
    assert_equal 0, LessonConflict.count
    assert_equal [ ], cl1.conflicts
    assert_equal true, cl1.verify_compatibility
  end
  
  test "move" do
    #
    # we create two conflicting lessons, we should have one intermediate
    # LessonConflict record, and then we move one lesson out of conflict 
    #
    assert_equal 0, Lesson.count
    assert_equal 0, LessonConflict.count
    assert cl1 = Lesson.create(:activated_topic => @at1, :start_date => @sd, :duration => @dur)
    assert cl1.valid?
    assert_equal 0, LessonConflict.count
    assert cl2 = Lesson.create(:activated_topic => @at2, :start_date => @sd, :duration => @dur)
    assert cl2.valid?
    assert_equal 1, LessonConflict.count
    #
    # now we move one of them
    #
    assert nt = @sd + (2 * @dur).minutes
    assert cl1.start_date = nt
    assert_equal @dur, cl1.duration
    assert cl1.save
    assert_equal 0, LessonConflict.count
    assert_equal [ ], cl2.conflicts
    assert_equal true, cl2.verify_compatibility
  
  end

  
  
end
