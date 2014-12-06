#
# $Id: course_test.rb 208 2010-01-06 20:20:10Z nicb $
#
require 'test/test_helper'

class CourseTest < ActiveSupport::TestCase

  fixtures :topics, :courses, :activated_topics

  def test_creation_destroy
    name = 'cucina'
    dur = 3
		acronym = 'CUC'
    assert c = Course.create(:name => name, :acronym => acronym, :duration => dur)
    assert c.valid?
    assert !c.frozen?
    assert_equal name, c.name
    assert_equal dur, c.duration
    c.destroy
    assert c.frozen?
  end

  def test_validation
    name = 'cucina'
    dur = 3
		acronym = 'CUC'
    assert c = Course.create()
    assert !c.valid?
    #
    assert c = Course.create(:name => name)
    assert !c.valid?
    #
    assert c = Course.create(:duration => dur)
    assert !c.valid?
    #
    assert c = Course.create(:acronym => acronym)
    assert !c.valid?
		#
    assert c = Course.create(:name => name, :duration => dur)
    assert !c.valid?
    #
		assert c = Course.create(:acronym => acronym, :duration => dur)
    assert !c.valid?
		#
		assert c = Course.create(:acronym => acronym, :name => name)
    assert !c.valid?
		#
    assert c = Course.create(:name => name, :acronym => acronym, :duration => 'three')
    assert !c.valid?
		#
		assert c = Course.create(:name => name, :acronym => "THIS_ACRONYM_IS_TOO_LONG", :duration => dur)
		assert !c.valid?
  end

	def test_uniqueness
    name = 'cucina'
    dur = 3
		acronym = 'CUC'
		#
		assert c = Course.create(:name => name, :acronym => acronym, :duration => dur)
		assert c.valid?
		#
		assert c1 = Course.create(:name => name, :acronym => acronym, :duration => dur)
		assert !c1.valid?
		#
		assert c1 = Course.create(:name => name, :acronym => 'CUC2', :duration => dur)
		assert !c1.valid?
		#
		assert c1 = Course.create(:name => 'coursename', :acronym => acronym, :duration => dur)
		assert !c1.valid?
	end

  def test_activation_deactivation_course
    name = 'cucina'
    dur = 3
		acronym = 'CUC'
    starting_year = "2006"

    assert c = Course.create(:name => name, :acronym => acronym, :duration => dur)
    assert c.valid?, "#{c.errors.full_messages.join(', ')}"
    assert cy = c.activate(starting_year)
    assert cy.valid?, "#{cy.errors.full_messages.join(', ')}"
    assert_equal 1, c.course_starting_years(true).size
    assert_equal starting_year.to_i, c.course_starting_years[0].starting_year

    assert c.deactivate(starting_year)
    assert_equal 0, c.course_starting_years(true).size
  end

  def test_topics
    assert year = 2006
    assert course = Course.find_by_name("Tecnico di Sala di Registrazione")
    assert course.activate(year)
    assert course.topics(true).blank?
  end

  def test_teachers
    assert year = 2006
    assert course = Course.find_by_name("Tecnico di Sala di Registrazione")
    assert course.activate(year)
    assert course.teachers(true).blank?
  end
end
