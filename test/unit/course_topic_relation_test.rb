#
# $Id: course_topic_relation_test.rb 292 2012-08-23 16:26:37Z nicb $
#
require 'test/test_helper'
require 'test/utilities/random'

class CourseTopicRelationTest < ActiveSupport::TestCase

  include Test::Utilities::StringHelper

  fixtures :topics, :course_starting_years, :activated_topics

  def setup
    assert @tds1 = course_starting_years(:tds_one)
    assert @tds1.valid?
    assert @bd1 = course_starting_years(:bd_one)
    assert @bd1.valid?
    assert @at = activated_topics(:informatica_year_one)
  end
  
  test "create and destroy" do
    #
    # should be tested with at least new-from-scratch csys and  possibly
    # ats (otherwise they are all already taken in fixtures)
    #
    assert tt = { :key => 'A', :desc => 'Affine' }
    assert mf = { :key => false, :desc => 'A Scelta' }
    assert ctr = CourseTopicRelation.create(:course_starting_year => random_course_starting_year,
                                            :activated_topic => @at,
                                            :teaching_typology => tt[:key],
                                            :course_year => 1,
                                            :mandatory_flag => mf[:key])
    assert ctr.valid?, "#{ctr.errors.full_messages.join(', ')}"
    assert_equal tt[:key], ctr.teaching_typology
    assert_equal tt[:desc], ctr.full_teaching_typology
    assert_equal mf[:key], ctr.mandatory_flag
    assert_equal mf[:desc], ctr.full_mandatory_flag
    assert ctr.destroy
    assert ctr.frozen?
  end

  test "validates uniqueness of" do
    assert tt = 'A'
    assert msgs = ['Course starting year has already been taken', 'Activated topic has already been taken']
    #
    # delete all at the beginning to make sure we're testing correctly
    #
    assert CourseTopicRelation.delete_all
    assert_equal 0, CourseTopicRelation.all.size

    assert ctr1 = CourseTopicRelation.create(:course_starting_year => @tds1,
                                            :course_year => 1,
                                            :activated_topic => @at,
                                            :teaching_typology => tt)
    assert ctr1.valid? # first time is valid
    assert ctr2 = CourseTopicRelation.create(:course_starting_year => @tds1,
                                            :course_year => 1,
                                            :activated_topic => @at,
                                            :teaching_typology => tt)
    assert !ctr2.valid? # second time is invalid
    assert_equal msgs.sort, ctr2.errors.full_messages.sort
    #
    # but if I change one of these three parameters
    #
    assert ctr2 = CourseTopicRelation.create(:course_starting_year => @bd1,
                                            :course_year => 1,
                                            :activated_topic => @at,
                                            :teaching_typology => tt)
    assert ctr2.valid? # we're valid again
  end

  test "validates presences" do
    assert tt = 'A'
    assert args = { :course_starting_year => random_course_starting_year, :activated_topic => @at,
                                            :teaching_typology => tt, :course_year => 2 }
    [ :course_starting_year, :activated_topic, :course_year ].each do
      |k|
      these_args = args.dup
      these_args.delete(k)
      assert ctr = CourseTopicRelation.create(these_args)
      assert !ctr.valid?
    end
    these_args = args.dup
    these_args.delete(:teaching_typology)
    assert ctr = CourseTopicRelation.create(these_args)
    assert ctr.valid?, "#{ctr.errors.full_messages.join(', ')}"
  end

  test "validates numericality of course_year" do
    assert tt = 'A'
    assert args = { :course_starting_year => random_course_starting_year, :activated_topic => @at,
                                            :teaching_typology => tt }
    ['test', 2, 2.0].each do
      |value|
      assert these_args = args.dup
      assert these_args[:course_year] = value
      if value.is_a?(Numeric) 
        if value.is_a?(Fixnum)
          should_be = true
        else
          should_be = false
        end
      else
        should_be = false
      end
      assert ctr = CourseTopicRelation.create(these_args)
      assert_equal should_be, ctr.valid?, "#{ctr.inspect} should be false and it is not"
    end
  end

  test "teaching typology selector" do
    assert should_be = CourseTopicRelation::TEACHING_TYPOLOGIES
    assert_equal should_be, CourseTopicRelation.teaching_typology_selector
  end

	test "is_current? method" do
		assert year_start = CourseStartingYear::CURRENT_AA - 10
		assert year_end   = CourseStartingYear::CURRENT_AA
		year_start.upto(year_end) do
			|year|
			assert csy = random_course_starting_year(year)
			1.upto(3) do
				|cy|
				current_should_be = year == (year_end - cy + 1) ? true : false
			  assert ctr = CourseTopicRelation.create(:activated_topic => @at, :course_starting_year => csy, :course_year => cy)
			  assert ctr.valid?
			  assert_equal current_should_be, ctr.is_current?
				assert ctr.destroy
				assert ctr.frozen?
			end
			assert csy.destroy
			assert csy.frozen?
		end
	end

private

	include Test::Utilities::Random

end
