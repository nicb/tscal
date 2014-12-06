#
# $Id: activated_topic_test.rb 298 2012-11-03 14:34:29Z nicb $
#
require 'test/test_helper'
require 'test/utilities/random'

require 'datetime'

class ActivatedTopicTest < ActiveSupport::TestCase

  include Test::Utilities::StringHelper

  fixtures :courses, :course_starting_years

  def setup
    assert @csy1 = course_starting_years(:tds_one)
    assert @csy1.valid?
    assert @csy2 = course_starting_years(:bd_one)
    assert @csy2.valid?
    assert @teacher1 = Teacher.create(:login => 'test_teacher_1', :password => 'testtest', :password_confirmation => 'testtest', :email => 'xxx@yyy.com', :last_name => 'T1', :first_name => 'Tfn1')
    assert @teacher1.valid?, @teacher1.errors.full_messages.join(', ')
    assert @teacher2 = Teacher.create(:login => 'test_teacher_2', :password => 'testtest', :password_confirmation => 'testtest', :email => 'xxx@yyy.com', :last_name => 'T2', :first_name => 'Tfn2')
    assert @teacher2.valid?, @teacher2.errors.full_messages.join(', ')
    assert @curr_aa = CourseStartingYear::CURRENT_AA
  end

  test "creation destruction" do
    args = { :topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2 }
    assert ac = ActivatedTopic.create(args)
    assert ac.valid?
    assert ac.destroy
    assert ac.frozen?    
    #
    # now let's test with some course_starting_year connection
    #
    CourseTopicRelation.delete_all # make sure no prior connection exists
    assert ac = ActivatedTopic.create(args)
    assert ac.valid?
    assert @csy1.course_topic_relations.create(:activated_topic => ac, :course_year => 1)
    assert_equal 1, @csy1.activated_topics(true).size
    assert_equal 1, ac.course_starting_years(true).size
    assert_equal 1, CourseTopicRelation.all.size
    assert ac.destroy
    assert ac.frozen?
    assert_equal 0, @csy1.activated_topics(true).size
    assert_equal 0, CourseTopicRelation.all.size
  end

  test 'presence' do
    args = 
    {
      :topic => random_topic,
      :teacher => @teacher1,
      :credits => 23,
      :duration => 35,
      :semester_start=> 1
    }
    args.keys.each do
      |k|
      a = args.dup
      a.delete(k)
      assert ac = ActivatedTopic.create(a)
      assert !ac.valid?
    end
  end

  test 'numericality' do
    wargs =
    {
      :credits => "gino",
      :duration => "peppe",
      :semester_start => "aldo"
    }
    args = 
    {
      :topic => random_topic,
      :teacher => @teacher1,
      :credits => 23,
      :duration => 35,
      :semester_start=> 1
    }
    wargs.keys.each do
      |k|
      a = args.dup
      a[k] = wargs[k]
      assert ac = ActivatedTopic.create(a)
      assert !ac.valid?
    end
  end

  test 'uniqueness' do
    assert topic = random_topic
    assert topic.valid?
    @csy1.activated_topics.clear; @csy2.activated_topics.clear
    #
    # simple uniqueness validation:
    #
    # on the same starting year, the same course with the same teacher
    # *can* be held (a teacher can do the same course more than once per year,
		# even in parallel)
    #
    args0 = 
    {
      :topic => topic,
      :teacher => @teacher1,
      :credits => 23,
      :duration => 35,
      :semester_start=> 1
    }
    assert ac1 = ActivatedTopic.create(args0)
    assert ac1.valid? # validating at the beginning
    assert ctr1 = @csy1.course_topic_relations.create(:activated_topic => ac1, :course_year => 1), "Failed! #{ctr1.inspect}"
    assert ctr1.valid?
    #
    # this raises an exception
    #
    assert ac2 = ActivatedTopic.create(args0)
    assert ac2.valid?
    assert ctr2 = @csy1.course_topic_relations.create(:activated_topic => ac2, :course_year => 1)
    assert ctr2.valid?
    ac1.destroy
    #
    # slightly more complex uniqueness validation:
    #
    # on the same starting year, the same course with *another* teacher
    # *can* be held
    #
    args1 = args0.dup
    args1.update(:teacher => @teacher2)
    assert ac1 = ActivatedTopic.create(args0)
    assert ac1.valid? # validating at the beginning
    assert ctr1 = @csy1.course_topic_relations.create(:activated_topic => ac1, :course_year => 1)
    assert ctr1.valid?
    #
    assert ac2 = ActivatedTopic.create(args1)
    assert ac2.valid?, ac2.errors.full_messages.uniq.join(', ')
    assert ctr2 = @csy1.course_topic_relations.create(:activated_topic => ac2, :course_year => 1)
    assert ctr2.valid?
    ac1.destroy; ac2.destroy
    #
    # now decidedly more complex: we validate that the same teacher can indeed
    # teach the same topic on two different years (different csy)
    #
    assert ac1 = ActivatedTopic.create(args0)
    assert ac1.valid? # validating at the beginning
    assert ctr1 = @csy1.course_topic_relations.create(:activated_topic => ac1, :course_year => 1)
    assert ctr1.valid?
    #
    assert ctr2 = @csy2.course_topic_relations.create(:activated_topic => ac1, :course_year => 1)
    assert ctr2.valid?
    ac1.destroy; ac2.destroy
  end
  
  test "verify compatibility" do
    # This test is with the right number of lessons
    assert start_date = Time.zone.local(2009,10,9)
    wdays = { 'Lunedì' => {'dur' => 120, 'start_hour' => 10, 'start_minute' => 00},'Venerdì' => {'dur' => 240, 'start_hour' => 18, 'start_minute' => 15}}
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    assert l = Lesson.generate_lesson_list(at, start_date, wdays)
    l.each {|ll| assert ll.save; assert ll.valid?}
    assert_equal l.size, at.lessons(true).size
    assert at.verify_compatibility
    assert_equal "", at.warnings.full_messages
    # This one with an exceeding lesson
    at.lessons << Lesson.create(:activated_topic => at, :start_date => Time.zone.local(2010,05,03,10,0), :duration => 180)
    at.reload
    assert !at.verify_compatibility
    lessonduration = 0
    at.lessons.each do
      |ldur|
      lessonduration += ldur.duration
    end
    assert_equal "Le #{lessonduration.to_f / 60.0} ore delle lezioni non corrispondono al monte ore del corso (#{at.duration} ore)", at.warnings.full_messages
    # This one with a missing lesson
    assert at.lessons.last.destroy
    assert at.reload
    assert at.lessons.last.destroy
    assert at.reload
    assert !at.verify_compatibility
    lessonduration = 0
    at.lessons.each do
      |ldur|
      lessonduration += ldur.duration
    end
    assert_equal "Le #{lessonduration.to_f / 60.0} ore delle lezioni non corrispondono al monte ore del corso (#{at.duration} ore)", at.warnings.full_messages
    # This one without lessons
    at.lessons.each do
      |atl|
      atl.destroy
    end
    assert_equal 0, at.lessons(true).size
    assert !at.verify_compatibility
    lessonduration = 0
    at.lessons.each do
      |ldur|
      lessonduration += ldur.duration
    end
    assert_equal "Le #{lessonduration.to_f / 60.0} ore delle lezioni non corrispondono al monte ore del corso (#{at.duration} ore)", at.warnings.full_messages
  end

	test 'delete_lessons' do
    assert start_date = Time.zone.local(2009,10,9)
    wdays = { 'Lunedì' => {'dur' => 120, 'start_hour' => 10, 'start_minute' => 00},'Venerdì' => {'dur' => 240, 'start_hour' => 18, 'start_minute' => 15}}
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
		assert at.lessons.size == 0
		assert_equal "Non sono attive lezioni per questo corso", at.delete_lessons 
    assert l = Lesson.generate_lesson_list(at, start_date, wdays)
    l.each {|ll| assert ll.save; assert ll.valid?}
		assert at.reload
		assert at.lessons.size != 0
		assert_equal "Tutte le lezioni di questo corso sono state cancellate", at.delete_lessons
		assert at.reload
		assert at.lessons.size == 0
	end

  test 'extra information fields default creation' do
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    assert_equal ActivatedTopic::DEFAULT_DELIVERY_TYPE, at.delivery_type
  end

  test 'extra information fields specific creation' do
    dt = 'CPc'
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2, :delivery_type => dt)
    assert at.valid?
    assert_equal dt, at.delivery_type
  end

  test 'extra information fields delivery type response' do
# FIXME: this needs to be fixed when associations are tested...
#   tt = 'A'
    dt = 'CPi'
    should_be = dt + 2.to_s
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2, :delivery_type => dt)
    assert at.valid?
#   assert_equal tt, at.teaching_typology
#   assert_equal should_be, at.delivery_type
  end

  test 'extra information fields selectors' do
    dt_should_be = [['Teorico Frontale', 'TF'], ['Compartecipato Collettivo', 'CPc'], ['Compartecipato Individuale', 'CPi']]
    assert_equal dt_should_be, ActivatedTopic.delivery_type_selector
  end

  test 'extra information long descriptors' do
    ActivatedTopic::DELIVERY_TYPES.each do
      |k, v|
      assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2, :delivery_type => k)
      assert at.valid?
      assert should_be = k
      assert should_be_extended = v
# FIXME: this must be fixed...
#     if k == 'CPi'
#       assert(should_be = at.teaching_typology == 'C' ? k + 1.to_s : k + 2.to_s)
#       assert(should_be_extended = at.teaching_typology == 'C' ? v + 1.to_s : v + 2.to_s)
#     end
#     assert_equal should_be, at.delivery_type
#     assert_equal should_be_extended, at.delivery_type_extended
      assert at.destroy
      assert at.frozen?
    end
  end

  test 'active query flag' do
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    assert !at.active? # no lessons related to it
    assert_equal 'S', at.activity_report
    #
    # now let's add a lesson
    #
    assert l = at.lessons.create(:start_date => Time.zone.local(2010,05,03,10,0), :duration => 180)
    assert l.valid?
    assert at.reload
    assert at.active?
    assert_equal 'A', at.activity_report
    #
    # now let's remove it
    #
    assert l.destroy
    assert l.frozen?
    assert at.reload
    assert !at.active?
    assert_equal 'S', at.activity_report
  end

  test 'administrative data' do
    #
    # when no administrative data is set, everything should be 0 or 0.0
    #
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    [:hours_in_mo, :hours_paid].each do
      |m|
      assert_equal 0, at.send(m)
    end
    [:teacher_net, :teacher_gross, :school_gross].each do
      |m|
      assert_equal 0.0, at.send(m)
    end
    assert at.destroy
    assert at.frozen?
    #
    # now let's set some data and verify it is correct
    #
    args =
    {
      :topic => random_topic,
      :teacher => @teacher1,
      :credits => 23,
      :duration => 37,
      :semester_start => 2,
      :hours_in_mo => 10,
      :hours_paid  => 20,
      :teacher_net => 1050.20,
      :teacher_gross => 1630.53,
      :school_gross =>  1980.23,
    }
    assert at = ActivatedTopic.create(args)
    assert at.valid?
    [:hours_in_mo, :hours_paid, :teacher_net, :teacher_gross, :school_gross].each do
      |m|
      assert_equal args[m], at.send(m)
    end
  end

  test 'notes' do
    note = "This is a normal note"
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2, :notes => note)
    assert at.valid?
    assert_equal note, at.notes
    assert at.destroy
    assert at.frozen?
    #
    # let's check if it takes in a very long note
    #
#   logger.silence(Logger::INFO) do # FIXME: I would like to silence this, but I can't seem to be able to do it :(
	    long_note = "This is a very long note; "
	    while long_note.size < 5.megabytes
	      long_note += long_note
	    end
	    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2, :notes => long_note)
	    assert at.valid?
	    assert_equal long_note, at.notes
#   end
  end

  test 'clone lessons' do
    Lesson.all.each { |l| assert l.destroy; assert l.frozen? }
    assert start_date = Time.zone.local(2009,10,9)
    wdays = { 'Lunedì' => {'dur' => 120, 'start_hour' => 10, 'start_minute' => 00}, 'Venerdì' => {'dur' => 240, 'start_hour' => 18, 'start_minute' => 15}}
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    assert ls = Lesson.generate_lesson_list(at, start_date, wdays)
    ls.each { |l| assert l.save; assert l.reload; assert l.valid?; assert !l.cloned?; assert_nil l.temp_clone_id }
    assert cls = at.clone_lessons
    cls.each_index do
      |i|
      assert cls[i].cloned?; assert cls[i].valid?
      assert_equal ls[i].id, cls[i].temp_clone_id
      ls[i].clone_attributes.keys { |k| assert_equal ls[i].send(k), cls[i].send(k) }
      assert !cls[i].conflicts?
    end
  end

  test 'associations' do
    assert csy1 = random_course_starting_year
    assert csy2 = random_course_starting_year
    #
    # test with append method (no possibility to set teaching_typology nor
    # mandatory flag))
    #
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    assert ctr1 = CourseTopicRelation.create(:activated_topic => at, :course_starting_year => csy1, :course_year => 2)
    assert ctr1.valid?
    assert ctr2 = CourseTopicRelation.create(:activated_topic => at, :course_starting_year => csy2, :course_year => 3) # this one is current
    assert ctr2.valid?
    assert at.course_topic_relations.<<(ctr1, ctr2)
    assert_equal 2, at.course_starting_years(true).size
    assert_equal at.id, at.course_starting_years[0].activated_topics[0].id
    assert_equal CourseTopicRelation::DEFAULT_TEACHING_TYPOLOGY, at.course_topic_relations[0].teaching_typology
    assert_equal CourseTopicRelation::DEFAULT_MANDATORY_FLAG, at.course_topic_relations[0].mandatory_flag
    #
    # now check destroy dependency
    #
    assert ctrs = CourseTopicRelation.find_all_by_activated_topic_id(at.id)
    assert_equal 2, ctrs.size
    assert at.destroy
    assert at.frozen?
    assert ctrs = CourseTopicRelation.find_all_by_activated_topic_id(at.id)
    assert_equal 0, ctrs.size
    #
    # test with create method
    #
    tt0 = 'A'; tt1 = 'C'
    mf0 = true; mf1 = false;
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    assert at.course_topic_relations.create(:course_starting_year => csy1, :teaching_typology => tt0, :mandatory_flag => mf0)
    assert at.course_topic_relations.create(:course_starting_year => csy2, :teaching_typology => tt1, :mandatory_flag => mf1)
    assert_equal tt0, at.course_topic_relations[0].teaching_typology
    assert_equal tt1, at.course_topic_relations[1].teaching_typology
    assert_equal mf0, at.course_topic_relations[0].mandatory_flag
    assert_equal mf1, at.course_topic_relations[1].mandatory_flag
  end

  test "link to course starting years" do
    #
    # the csys hash is done like this:
	  #   { "xxx" => { :status => '0', :teaching_typology => 'C', :mandatory_flag
	  #           => true, :course_year => 2 }, "yyy" => { :status => '1', ... }
	  #   where 'xxx' and 'yyy' are ids for course starting year records,
	  #   the :status fields denotes linking, and all other params are arguments
	  #   of the course_topic_relations records to be created
	  #
    assert csys_args = random_course_starting_years
		assert linked_csys = effectively_linked_csys(csys_args)
    assert num_of_csys_linked = linked_csys.size
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    assert at.link_to_course_starting_years([ csys_args ])
    assert_equal num_of_csys_linked, at.course_starting_years(true).size
    assert_equal linked_csys.map { |csy| csy.id }.sort, at.course_starting_years.map { |csy| csy.id }.sort
  end

  test "full prints" do
    # create
    assert csys_args = random_course_starting_years
		assert linked_csys = effectively_linked_csys(csys_args)
    assert num_of_csys_linked = linked_csys.size
		assert num_of_csys_linked > 0
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    assert at.link_to_course_starting_years([ csys_args ])
    assert_equal num_of_csys_linked, at.course_starting_years(true).size
		assert csys_sort_map = linked_csys.map { |csy| csy.id }.sort
		assert_equal csys_sort_map, at.course_starting_years.map { |csy| csy.id }.sort
    # test
    assert_equal linked_csys.map { |csy| csy.course.acronym }.uniq.sort.join('/'), at.all_courses
    assert_equal linked_csys.map { |csy| csy.full_course_acronym }.uniq.sort.join('/'), at.all_full_courses
    assert_equal linked_csys.map { |csy| csy.roman_year }.sort.uniq.join('/'), at.all_roman_years
    assert_equal linked_csys.map { |csy| csy.anno }.sort.uniq.join('/'), at.all_annos
    assert all_ctrs = linked_csys.map { |csy| CourseTopicRelation.find_by_course_starting_year_id(csy.id) }
    assert_equal all_ctrs.map { |ctr| ctr.teaching_typology }.sort.uniq.join('/'), at.all_teaching_typologies
  end

  test "option values" do
    assert csys_args = random_course_starting_years
		assert linked_csys = effectively_linked_csys(csys_args)
    assert num_of_csys_linked = linked_csys.size
		assert num_of_csys_linked > 0
    assert at = ActivatedTopic.create(:topic => random_topic, :teacher => @teacher1, :credits => 23, :duration => 37, :semester_start => 2)
    assert at.valid?
    assert at.link_to_course_starting_years([ csys_args ])
    assert_equal num_of_csys_linked, at.course_starting_years(true).size
    assert_equal linked_csys.map { |csy| csy.id }.sort, at.course_starting_years.map { |csy| csy.id }.sort
    # test
    assert_equal at.truncated_topic_and_level + ' (' + linked_csys.map { |csy| csy.anno }.sort.uniq.join('/') + ')', at.option_value
  end

# test "all sorted by topic name" do 
#	  assert random_environment(@teacher1)
#   assert ats=ActivatedTopic.all_sorted_by_topic_name
#	  assert ats.size > 0
#	  assert topic_names_should_be = Topic.all(:order => 'name').map { |t| t.name }
# 	assert_equal topic_names_should_be, ats.map { |at| at.topic.name }
# end

	test "currently active topics" do
		assert random_environment(@teacher1)
    assert ats=ActivatedTopic.currently_active_topics
		assert ats.size > 0
	  assert years_are_effectively_current(ats)
	end

private

  def years_are_effectively_current(ats)
		local_results = []
    ats.each do
      |at| 
			lr = false
      at.course_topic_relations(true).each do
        |ctr|
				assert cy = ctr.course_year
				assert sy_should_be = @curr_aa - cy + 1
				lr = true if sy_should_be == ctr.course_starting_year.starting_year
      end
			unless lr
				if at.lessons(true).size > 0
					assert now = Time.zone.now
					lr = true if at.lessons.first.start_date <= now && at.lessons.last.end_date >= now
				end
			end
			local_results << lr
    end
		local_results.include?(false) ? false : true
  end

	def effectively_linked_csys(csys_args)
    linked_csys = csys_args.keys.map do
			|id|
		  CourseStartingYear.find(id) if csys_args[id]['status'] == '1'
		end.compact
		linked_csys
	end

	include Test::Utilities::RandomEnvironment
  
end
