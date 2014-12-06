#
# $Id: course_starting_year_test.rb 292 2012-08-23 16:26:37Z nicb $
#
require 'test/test_helper'

class CourseStartingYearTest < ActiveSupport::TestCase
  fixtures :courses, :users, :activated_topics, :course_topic_relations
  
  def setup
    assert @course = courses(:tds)
    assert @course.valid?
    assert @teacher = users(:nicb)
    assert @at = activated_topics(:informatica_year_three)
    assert @at.valid?
    assert @starting_year = CourseStartingYear::CURRENT_AA - 1
		assert @color = "#F00F88"
    assert @ctr = course_topic_relations(:i3_tds_y_three)
    assert @ctr.valid?
  end

   def test_creation_destroy
     assert csy = CourseStartingYear.create(:course_id => @course, :starting_year => @starting_year, :color => @color)
     assert csy.valid?
     assert !csy.frozen?
     csy.destroy
     assert csy.frozen?    
   end
   
   def test_validation
     assert csy = CourseStartingYear.create(:course_id => @course)
     assert !csy.valid?
 
     assert csy = CourseStartingYear.create(:color => @color)
     assert !csy.valid?
 
     assert csy = CourseStartingYear.create(:starting_year => @starting_year)
     assert !csy.valid?
 
 		assert csy = CourseStartingYear.create(:course_id => @course, :starting_year => @starting_year)
     assert !csy.valid?
 
 		assert csy = CourseStartingYear.create(:course_id => @course, :color => @color)
     assert !csy.valid?
 
 		assert csy = CourseStartingYear.create(:color => @color, :starting_year => @starting_year)
     assert !csy.valid?
 
   end
 
   def test_uniqueness
     assert csy = CourseStartingYear.create(:course_id => @course, :starting_year => @starting_year, :color => @color)
     assert csy.valid?
 
     assert csy1 = CourseStartingYear.create(:course_id => @course, :starting_year => @starting_year, :color => @color)
     assert !csy1.valid?
   end
 
   test "proxying" do
     assert csy = CourseStartingYear.create(:course_id => @course, :starting_year => @starting_year, :color => @color)
     assert ctr = csy.course_topic_relations.create(:course_starting_year => csy, :activated_topic => @at, :course_year => 3)
     assert ctr.valid?
     assert !csy.activated_topics.blank?
     assert !csy.teachers.blank?
     assert_equal @at.teacher.id, csy.teachers.first.id
   end
 
   def test_age_methods
     assert old_sy = (Time.zone.local(2009) - 5.years).year
     assert old_csy = CourseStartingYear.create(:course => @course, :starting_year => old_sy)
     assert young_sy = (Time.zone.now - 1.years).year
     assert young_csy = CourseStartingYear.create(:course => @course, :starting_year => young_sy)
     assert old_csy.old?
     assert !young_csy.old?
   end
 
   def test_anno_methods
     assert our_aa = CourseStartingYear::CURRENT_AA
     previous_years = []
     our_aa.downto(our_aa-8) do
       |y|
       the_map = {}
       assert the_map[:sy] = y
       the_map[:anno] = case
                         when y == our_aa : 'Primo Anno'
                         when y == our_aa-1 : 'Secondo Anno'
                         when y == our_aa-2 : 'Terzo Anno'
                         else 'Fuori Corso'
                        end
       previous_years << the_map
     end
     previous_years.each do
       |m|
       assert csy = CourseStartingYear.find_or_create_by_course_id_and_starting_year(:course_id => @course.id, :starting_year => m[:sy], :color => '#ff00ff')
       assert csy.valid?, "CourseStartingYear.create(:course => #{@course}, :starting_year => #{m[:sy]}) failed => #{csy.errors.full_messages.join(', ')}"
       assert_equal m[:sy], csy.starting_year
       assert_equal m[:anno], csy.anno, "m[:anno] (#{m[:anno]}) != csy.anno (#{csy.anno})"
       assert csy.destroy
       assert csy.frozen?
     end
   end

   test "roman year" do
     assert cur_aa = CourseStartingYear::CURRENT_AA
     assert should_be = [ 'I', 'II', 'III', 'SFC', 'SFC', 'SFC' ]
     0.upto(5) do
       |y|
       sy = cur_aa - y
       assert csy = CourseStartingYear.find_or_create_by_course_id_and_starting_year(:course_id => @course.id, :starting_year => sy, :color => '#ff00ff')
       assert csy.valid?, "CourseStartingYear.create(:course => #{@course}, :starting_year => #{sy}) failed => #{csy.errors.full_messages.join(', ')}"
       assert should_be[y], csy.roman_year
       assert csy.destroy
       assert csy.frozen?
     end
   end

   test "roman to julian year" do
     assert cur_aa = CourseStartingYear::CURRENT_AA
     assert roman_years = %w(I II III)
     0.upto(2) do
       |y|
       sy = cur_aa - y
       assert_equal sy, CourseStartingYear.roman_to_julian_year(roman_years[y])
     end
   end

   test "sorted all" do
     #
     # clear all csys first
     #
     CourseStartingYear.all.each { |csy| assert csy.destroy; assert csy.frozen? }
     assert courses =
     [
       Course.create(:name => 'AAA', :acronym => 'AA', :duration => 3),
       Course.create(:name => 'BBB', :acronym => 'BB', :duration => 3),
       Course.create(:name => 'CCC', :acronym => 'CC', :duration => 3),
     ]
     courses.each { |c| assert c.valid? }
     csys = []
     courses.each do
       |c|
       0.downto(-2) do
         |n|
         y = CourseStartingYear::CURRENT_AA + n
         assert csys << CourseStartingYear.create(:course => c, :starting_year => y, :color => '#ff00ff')
         assert csys.last.valid?
       end
     end
     assert !csys.blank?
     assert_equal csys, CourseStartingYear.sorted_all
   end

   test "topic activation" do
     assert csy_args = { :course_id => @course, :starting_year => @starting_year, :color => @color }
     assert at_args = { :topic => @at.topic, :teacher => @teacher,
                                  :credits => 2, :duration => 20,
                                  :semester_start => 4, :delivery_type => 'TF' }
     assert at_plus_ctr_args = at_args.dup
		 assert cy = CourseStartingYear::CURRENT_AA - @starting_year + 1
     assert at_plus_ctr_args.update(:ctr_args => { :course_year => cy, :mandatory_flag => true, :teaching_typology => CourseTopicRelation::TEACHING_TYPOLOGIES_HASH['C'], :status => 1 })
     #
     # simple activation
     #
     assert csy = CourseStartingYear.create(csy_args)
     assert csy.valid?
     assert at = csy.topic_activate(at_args)
     assert at.valid?, "topic_activate failed: #{at.errors.full_messages.join(', ')}"
     assert_nil CourseTopicRelation.find_by_activated_topic_id_and_course_starting_year_id(at.id, csy.id)
     assert csy.activated_topics(true).blank?
     assert at.course_starting_years(true).blank?
     assert at.destroy
     assert at.frozen?
     assert csy.destroy
     assert csy.frozen?
     #
     # activation with course topic relation
     #
     assert csy = CourseStartingYear.create(csy_args)
     assert csy.valid?
     assert at = csy.topic_activate(at_plus_ctr_args)
     assert at.valid?, "topic_activate failed: #{at.errors.full_messages.join(', ')}"
     assert CourseTopicRelation.find_by_activated_topic_id_and_course_starting_year_id(at.id, csy.id)
     assert !csy.activated_topics(true).blank?
     assert !at.course_starting_years(true).blank?
   end

end
