#
# $Id: lesson_controller_test.rb 253 2010-08-28 21:16:10Z nicb $
#
require 'test/test_helper'

require 'datetime'

class LessonController # extension to read the flash (protected method)
  def read_flash
    return flash
  end
end

class LessonControllerTest < ActionController::TestCase

  fixtures :users, :topics, :course_starting_years, :activated_topics, :lessons
  
  def setup
    assert @admin = users(:moro)
    assert @start_date = sd = Time.zone.local(2009, 11, 9)
    assert @at = activated_topics(:informatica_year_one)
    assert @wdays = { 'Martedì' => {'dur' => 120, 'start_hour' => 10, 'start_minute' => 00},'Venerdì' => {'dur' => 300, 'start_hour' => 18, 'start_minute' => 15}}
    assert @new01_args = {"days"=>["0", "0", "Martedì", "0", "0", "Venerdì", "0"], "date"=>{"start(1i)"=>sd.year.to_s, "start(2i)"=>sd.month.to_s, "start(3i)"=>sd.day.to_s}}
    assert @new02_args = {"Martedì"=>{"dur"=>"120", "time(1i)"=>"2009", "time(2i)"=>"8", "time(3i)"=>"28", "time(4i)"=>"09", "time(5i)"=>"30"}, "Venerdì"=>{"dur"=>"240", "time(1i)"=>"2009", "time(2i)"=>"8", "time(3i)"=>"28", "time(4i)"=>"12", "time(5i)"=>"00"}}
    assert @new03_args = {"00"=>{"minute"=>"00", "minutes"=>"240", "hour"=>"12", "day(1i)"=>"2009", "day(2i)"=>"9", "day(3i)"=>"3"}, "01"=>{"minute"=>"30", "minutes"=>"120", "hour"=>"09", "day(1i)"=>"2009", "day(2i)"=>"9", "day(3i)"=>"7"}, "02"=>{"minute"=>"00", "minutes"=>"240", "hour"=>"12", "day(1i)"=>"2009", "day(2i)"=>"9", "day(3i)"=>"10"}, "03"=>{"minute"=>"30", "minutes"=>"120", "hour"=>"09", "day(1i)"=>"2009", "day(2i)"=>"9", "day(3i)"=>"14"}, "04"=>{"minute"=>"00", "minutes"=>"240", "hour"=>"12", "day(1i)"=>"2009", "day(2i)"=>"9", "day(3i)"=>"17"}, "05"=>{"minute"=>"30", "minutes"=>"120", "hour"=>"09", "day(1i)"=>"2009", "day(2i)"=>"9", "day(3i)"=>"21"}, "06"=>{"minute"=>"00", "minutes"=>"240", "hour"=>"12", "day(1i)"=>"2009", "day(2i)"=>"9", "day(3i)"=>"24"}, "07"=>{"minute"=>"30", "minutes"=>"120", "hour"=>"09", "day(1i)"=>"2009", "day(2i)"=>"9", "day(3i)"=>"28"}, "08"=>{"minute"=>"00", "minutes"=>"240", "hour"=>"12", "day(1i)"=>"2009", "day(2i)"=>"10", "day(3i)"=>"1"}, "09"=>{"minute"=>"30", "minutes"=>"120", "hour"=>"09", "day(1i)"=>"2009", "day(2i)"=>"10", "day(3i)"=>"5"}}
    assert lessons = Lesson.generate_lesson_list(@at, @start_date, @wdays)
    lessons.each { |l| assert l.save; assert l.valid? }
    assert @lesson = lessons.first
    assert @lesson.valid?
  end
  
  test "auth filtering" do
    actions = [ :create ]
    actions.each do
      |action|
	    #
	    # try getting the index without authorization
	    #
	    get action, { :id => @at.id }
	    assert_redirected_to(:controller => :account, :action => :login)
	    #
	    # now be authorized to do it
	    #
	    get action, { :id => @at.id }, { :user => @admin }
	    assert_response :success
    end
  end

	def test_edit_lesson
		xhr :get, :edit_lesson, {:id => @lesson.id}, { :user => @admin }
		assert_response :success

    new_l = Lesson.new(:activated_topic => @lesson.activated_topic, :start_date => @lesson.start_date, :duration => 30)

    xhr :post, :update, { 'id' => @lesson.id.to_s, 'lesson' => { "duration" => new_l.duration.to_s, "start_date"=>{"start_date(1i)"=>new_l.start_date.year.to_s, 'start_date(2i)' => new_l.start_date.month.to_s, 'start_date(3i)' => new_l.start_date.day.to_s, "minute"=> new_l.start_date.min.to_s, "hour" => new_l.start_date.hour.to_s }}}, { :user => @admin }
		assert_redirected_to '/'
    assert @lesson.reload
    assert_equal new_l.start_date, @lesson.start_date
    assert_equal new_l.end_date, @lesson.end_date
    assert_equal new_l.duration, @lesson.duration

	end

private

  def clear_all_lessons
    Lesson.all.each { |l| assert l.destroy; assert l.frozen? }
    assert_equal 0, Lesson.all.size
    assert Lesson.all.blank?
  end

end
