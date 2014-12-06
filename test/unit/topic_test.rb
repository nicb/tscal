#
# $Id: topic_test.rb 267 2011-03-02 13:28:29Z cerbero $
#
require 'test/test_helper'

class TopicTest < ActiveSupport::TestCase
	
	fixtures :users
	
	def setup
		@name = "ciccio"
	  @name2 = "shortnm"
		@acronym = "CI"
		@acronym2 = "SH"
		@acronym3= "boh"
		@color = "#FF093F"
		@date1 = Time.zone.local(2011,03,02,14,0)
		@date2 = Time.zone.local(2011,03,02,15,0)
	end

  def test_creation_destroy
    assert t = Topic.create(:name => @name, :acronym => @acronym, :color => @color)
    assert t.valid?

    t.destroy
    assert t.frozen?
  end

  def test_validations
    assert t = Topic.create()
    assert !t.valid?

    assert t = Topic.create(:level => 23)
    assert !t.valid?

    assert t = Topic.create(:name => @name, :level => '23')
    assert !t.valid?

    assert t = Topic.create(:name => @name, :level => '23', :acronym => @acronym)
    assert !t.valid?

    assert t = Topic.create(:name => @name, :level => '23', :acronym => @acronym, :color => @color)
    assert t.valid?
		assert t.destroy
		assert t.frozen?

    assert t0 = Topic.create(:name => @name, :acronym => @acronym, :color => @color)
    assert t0.valid?
    assert t1 = Topic.create(:name => @name)
    assert !t1.valid?
    t0.destroy
    assert t0.frozen?
    t1.destroy
    assert t1.frozen?

    assert t0 = Topic.create(:name => @name, :level => '1', :acronym => @acronym, :color => @color)
    assert t0.valid?, "#{t0.errors.full_messages.join(', ')}"
    assert t1 = Topic.create(:name => @name, :level => '2', :acronym => @acronym, :color => @color)
    assert t1.valid?, "#{t1.errors.full_messages.join(', ')}"
    assert t2 = Topic.create(:name => @name, :level => '1', :acronym => @acronym, :color => @color)
    assert !t2.valid?, "#{t2.errors.full_messages.join(', ')}"    
  end

	def test_name_display
		assert t = Topic.create(:name => @name, :level => '1', :acronym => @acronym)
#		the name is shorter than 16 digits, so it should output the name and not the acronym.
		assert d = t.name + ' ' + t.level.to_s		
		assert_equal t.display, d
#		the name is shorter than 16 digits, so it should output the name and not the acronym (test without level).
		assert t0 = Topic.create(:name => @name2, :acronym => @acronym2)
		assert d0 = t0.name
		assert_equal t0.display, d0
#		the name is longer than 16 digits, so it should output the acronym (test without level).
		assert t1 = Topic.create(:name => "Extremly looooooooooooooooooooong", :acronym => "EL")
		assert d1 = "EL"
		assert_equal t1.display, d1
#		the name is longer than 16 digits, so it should output the acronym.				
		assert t2 = Topic.create(:name => "Extremly long and boring name for a topic", :level => '1', :acronym => "ELABNFAT")
		assert d2 = "ELABNFAT" + ' ' + t2.level.to_s
		assert_equal t2.display, d2	
	end

	def test_name_display_tooltip
		assert t = Topic.create(:name => @name, :level => '1', :acronym => @acronym)
		assert dt = t.name + ' ' + t.level.to_s
		assert_equal t.display_tooltip, dt
#		now without level
		assert t0 = Topic.create(:name => @name2, :acronym => @acronym2)
		assert dt0 = t0.name
		assert_equal t0.display_tooltip, dt0
#		now with long name
		assert t1 = Topic.create(:name => "Extremly looooooooooooooooooooong", :acronym => "EL", :level => 5)
		assert dt1 = t1.name + ' ' + t1.level.to_s
		assert_equal t1.display_tooltip, dt1
#		now without level
		assert t2 = Topic.create(:name => "Extremly long and boring name for a topic", :acronym => "ELABNFAT")
		assert dt2 = t2.name
		assert_equal t2.display_tooltip, dt2
	end

	test "acronym =" do
		assert t = Topic.create(:name => @name, :level => '1', :acronym => @acronym3, :color => "#FFFFFF")
		assert t.valid?, "#{t.errors.full_messages.join(', ')}"
		assert_equal @acronym3.upcase, t.acronym
		# now we test the update
		assert t.update_attributes!(:acronym => @acronym3)
		assert t.reload.valid?, "#{t.errors.full_messages.join(', ')}"
		assert_equal @acronym3.upcase, t.acronym
	end
	
	test "color string validation" do
		assert t = Topic.create(:name => "test", :level => '1', :acronym => "tst", :color => "#FFEE00")
		assert t.valid? , t.errors.full_messages.join(', ')
		assert wrong_colors=["\"#FFEE00\"","test","—·∞Ç}{’»ı","'#ffee00'"]
		wrong_colors.each do
			|wc|
			assert !t.update_attributes(:color => wc)
		end
	end
	
	test "wrong color string" do
		assert teacher_parms={:login => 'tester',:password => '12345',:password_confirmation => '12345',:last_name => 'tester',:first_name => 'tester', :email => 'tester@nouser.com'}
		assert teacher = Teacher.create(teacher_parms)

		assert teacher.valid? , teacher.errors.full_messages.join(', ')
		assert t = Topic.create(:name => "test", :level => '1', :acronym => "tst", :color => "#FFEE00")
		assert t.valid? , t.errors.full_messages.join(', ')
		assert wrong_colors=["\"#FFEE00\"","test","—·∞Ç}{’»ı","'#ffee00'","#FFFE00"]
		assert count=0
		wrong_colors.each do
			|wc|
			res=t.update_attributes(:color => wc)
			if res 
				assert t.valid?, "#{t.errors.full_messages.join(', ')}"
				assert at = t.activated_topics.create(:teacher => teacher,:duration => 30, :semester_start => 1, :credits => 4)  
				assert at.valid? , at.errors.full_messages.join(', ')
				assert l=at.lessons.create(:start_date =>@date1,:end_date => @date2 )
				assert l.valid? , l.errors.full_messages.join(', ')
				assert l.background_color
				assert count+=1
			else 
				assert !res
			end
		end
		assert_equal 1,count 
		
	end
end
