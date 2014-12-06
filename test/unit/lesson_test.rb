#
# $Id: lesson_test.rb 298 2012-11-03 14:34:29Z nicb $
#
require 'test/test_helper'

require 'datetime'
require 'fixnum'

require 'test/utilities/lesson_helper'

class LessonTest < ActiveSupport::TestCase

  fixtures :topics, :course_starting_years, :activated_topics, :blacklisted_dates
  
  def setup
    assert @t = topics(:informatica_1)
    assert @csy1 = course_starting_years(:tds_one)
    assert @csy1.valid?
    assert @at = activated_topics(:informatica_year_one)
    assert @at.valid?
    assert @at2 = activated_topics(:pianoforte_year_one)
    assert @at2.valid?, "Invalid @at2: #{@at2.errors.full_messages.join(', ')}"
    assert @start_date = Time.zone.local(2009,8,24)
    @wdays = { 'Martedì' => {'dur' => 120, 'start_hour' => 10, 'start_minute' => 00},'Venerdì' => {'dur' => 300, 'start_hour' => 18, 'start_minute' => 15}}
    assert @atpiano = activated_topics(:pianoforte_year_one)
    assert @atpiano.valid?
  end
  
  test "generate lesson list" do
    should_be = [
      Lesson.new(:activated_topic => @at, :start_date => Time.zone.local(2009,8,25,10,00), :duration =>  120),
      Lesson.new(:activated_topic => @at, :start_date => Time.zone.local(2009,8,28,18,15), :duration =>  300),
      Lesson.new(:activated_topic => @at, :start_date => Time.zone.local(2009,9,1,10,00), :duration =>  120),
      Lesson.new(:activated_topic => @at, :start_date => Time.zone.local(2009,9,4,18,15), :duration =>  60),
    ].sort { |a, b| a.start_date <=> b.start_date }
    should_be.each {|l| assert l}
    assert lessons = Lesson.generate_lesson_list(@at, @start_date, @wdays).sort { |a, b| a.start_date <=> b.start_date }
    should_be.each_index do
      |i|
      all_diffs = []
      should_be[i].attributes.keys do
        |k|
        all_diffs << "should_be[#{i}].#{k}(#{should_be[i].send(k)}) != lessons[#{i}].#{k}(#{lessons[i].send(k)})" if should_be[i].send(k) != lessons[i].send(k)
      end
      assert_equal should_be[i], lessons[i], "Differences: \"#{all_diffs.join(', ')}\""
    end
  end
  
  test "creation and destroy" do
    assert lessons = Lesson.generate_lesson_list(@at, @start_date, @wdays)
    lessons.each do
      |l|
      assert l.save
      assert l.valid?
    end
    lessons.each do
      |l|
      assert l.destroy
      assert l.frozen?
    end
  end

  test "end time" do
    #before creation
    assert d = Time.zone.local(2009,9,4,18,15)
    dur = 75
    assert ed = d.since(dur.minutes)
    [:new, :create].each do
      |m|
      assert l = Lesson.send(m, :activated_topic => @at, :start_date => d, :duration =>  dur)
      assert l.valid? if m == :create
      assert_equal ed, l.end_date
    end
  end
  
  class LessonSupport
    attr_reader :lesson, :conflict, :messages
    def initialize(c, l, m = "")
      @conflict = c
      @lesson = l
      @messages = m
    end
  end
  
  test "conflicts" do
    clear_all_lessons
    assert ref = Lesson.create(:activated_topic => @at, :start_date => Time.zone.local(2009,9,8,10,00), :duration =>  60)
    assert ref.valid?
    [:new, :create].each do
      |m|
      assert testers = [
				LessonSupport.new(false, Lesson.send(m, :activated_topic => @at, :start_date => Time.zone.local(2009,9,7,10,00), :duration =>  60)),
				LessonSupport.new(true, Lesson.send(m, :activated_topic => @at, :start_date => Time.zone.local(2009,9,8,9,00), :duration =>  75)),
				LessonSupport.new(true, Lesson.send(m, :activated_topic => @at, :start_date => Time.zone.local(2009,9,8,10,00), :duration =>  60)),
				LessonSupport.new(true, Lesson.send(m, :activated_topic => @at, :start_date => Time.zone.local(2009,9,8,10,15), :duration =>  30)),
				LessonSupport.new(true, Lesson.send(m, :activated_topic => @at, :start_date => Time.zone.local(2009,9,8,9,00), :duration =>  180)),
				LessonSupport.new(true, Lesson.send(m, :activated_topic => @at, :start_date => Time.zone.local(2009,9,8,10,30), :duration =>  60)),
				LessonSupport.new(false, Lesson.send(m, :activated_topic => @at, :start_date => Time.zone.local(2009,9,8,11,00), :duration =>  60)),
				LessonSupport.new(false, Lesson.send(m, :activated_topic => @at, :start_date => Time.zone.local(2009,9,8,9,00), :duration =>  60)),
				LessonSupport.new(false, Lesson.send(m, :activated_topic => @at, :start_date => Time.zone.local(2009,9,9,10,00), :duration =>  60))
      ]
      testers.each_with_index do
	      |t, i|
        assert t.lesson.valid?
      end
      n_conflicts = testers.map { |t| t if t.conflict }.compact.size
      #
      # we test:
      # - each new lesson against reference (should have 1 conflict only)
      # - reference against all created lessons (should have all conflicts)
      #
      case m
      when :new : testers.each do
        |t|
        assert_equal t.conflict, t.lesson.conflicts?
        if t.conflict
          assert_equal 'gray', t.lesson.course_color
          assert_equal 'gray', t.lesson.title_color
          assert_equal 'black', t.lesson.background_color
        end
      end
      when :create : assert_equal n_conflicts, ref.conflicts.size
      end
    end
  end

  include Test::Utilities::LessonHelper

	#
	# <tt>conflicts among different csys</tt>: in the present test all csys are
	# connected to current years.
	#
  test "conflicts among different csys" do
		assert this_year = CourseStartingYear::CURRENT_AA
    assert csy1 = course_starting_years(:tds_one)
    assert csy1.valid?
    assert csy2 = course_starting_years(:tds_two)
    assert csy2.valid?
    assert csy3 = course_starting_years(:tds_old)
    assert csy3.valid?
    assert ats = create_many_activated_topics(5)
		#
		# four out of five +ActivatedTopic+s use current +course_years+
		#
    0.upto(3) do
      |n|
      csyvar = "csy#{(n/2.0).floor+1}"
			csy_starting_year = eval("#{csyvar}.starting_year")
      cy = 1
      eval_string = "#{csyvar}.course_topic_relations.create(:activated_topic => ats[#{n}], :course_year => #{cy})"
      eval(eval_string)
			assert ats[n].course_starting_years(true).size > 0
    end
		#
		# the last +ActivatedTopic+ use a non-current +course_year+ (outdated)
		# however, course_starting_years do still show in the activated_topic
		# association
		#
    csyvar = "csy#{(4/2.0).floor+1}"
		csy_starting_year = eval("#{csyvar}.starting_year")
    cy = CourseStartingYear::CURRENT_AA - csy_starting_year # == not current
    eval_string = "#{csyvar}.course_topic_relations.create(:activated_topic => ats[4], :course_year => #{cy})"
    eval(eval_string)
		assert_equal 1, ats[4].course_starting_years(true).size
    #
    # superimposed but non-conflicting lessons
    #
    clear_all_lessons
    assert l1 = Lesson.create(:activated_topic => ats[0], :start_date => Time.zone.local(this_year,2,15,9,0), :duration => 120)
    assert l1.valid?
    assert l2 = Lesson.create(:activated_topic => ats[3], :start_date => Time.zone.local(this_year,2,15,9,0), :duration => 120)
    assert l2.valid?
    assert_equal false, l1.conflicts?
    assert_equal false, l2.conflicts?
    #
    # superimposed *and* conflicting lessons
    #
    clear_all_lessons
    assert l1 = Lesson.create(:activated_topic => ats[0], :start_date => Time.zone.local(this_year,2,15,9,0), :duration => 120)
    assert l1.valid?
    assert l2 = Lesson.create(:activated_topic => ats[0], :start_date => Time.zone.local(this_year,2,15,9,0), :duration => 120)
    assert l2.valid?
    assert_equal [l2], l1.conflicts
    assert_equal [l1], l2.conflicts
    #
    # superimposed *and* conflicting lessons
    # with multiple csys
    #
    clear_all_lessons
    assert l1 = Lesson.create(:activated_topic => ats[2], :start_date => Time.zone.local(this_year,2,15,9,0), :duration => 120)
    assert l1.valid?
    assert l2 = Lesson.create(:activated_topic => ats[3], :start_date => Time.zone.local(this_year,2,15,9,0), :duration => 120)
    assert l2.valid?
    assert_equal [l2], l1.conflicts
    assert_equal [l1], l2.conflicts
		#
    # superimposed *and* conflicting lessons
		# but with an outdated course starting years (== should not conflict)
		#
    clear_all_lessons
    assert l1 = Lesson.create(:activated_topic => ats[0], :start_date => Time.zone.local(this_year,2,15,9,0), :duration => 120)
    assert l1.valid?
    assert l2 = Lesson.create(:activated_topic => ats[4], :start_date => Time.zone.local(this_year,2,15,9,0), :duration => 120)
    assert l2.valid?
    assert_equal false, l1.conflicts?
    assert_equal false, l2.conflicts?
  end

  test "conflicts when changing dates" do
    clear_all_lessons
    assert ref = Lesson.create(:activated_topic => @at, :start_date => Time.zone.local(2009,9,8,10,00), :duration =>  60)
    assert ref.valid?
    #
    # initially non conflicting
    #
    assert l = Lesson.create(:activated_topic => @at, :start_date => Time.zone.local(2009,9,8,11,00), :duration =>  60)
    assert l.valid?
    assert cl = l.clone
    assert cl.valid?
    assert_equal false, ref.conflicts?
    assert_equal false, l.conflicts?
    assert_equal false, cl.conflicts?
    #
    # now we anticipate l so there's a conflict
    #
    assert l.update_attributes!(:start_date => Time.zone.local(2009,9,8,10,30))
    assert_equal true, ref.conflicts?
    assert_equal true, l.conflicts?
    #
    # clone should still be ok
    #
    assert_equal false, cl.conflicts?
    #
    # now we change the clone too and it should conflict
    #
    assert cl.save
    assert cl.start_date = Time.zone.local(2009,9,8,9,30)
    assert_equal true, cl.conflicts?
  end

  test "verify compatibility" do
    clear_all_lessons
    assert ref = Lesson.create(:activated_topic => @at, :start_date => Time.zone.local(2009,9,8,10,00), :duration =>  60)
    assert ref.valid?
    args = [
      [true, {:activated_topic => @atpiano, :start_date => Time.zone.local(2009,9,8,10,00), :duration =>  60}, "Questa lezione è in conflitto con la lezione di #{@at.topic.display_tooltip} di #{@at.teacher.full_name} (#{ref.time})", "Questa lezione è in conflitto con la lezione di #{@at.topic.display_tooltip} di #{@at.teacher.full_name} (#{ref.time})"],
      [false, {:activated_topic => @atpiano, :start_date => Time.zone.local(2009,9,18,10,00), :duration =>  60}, '', ''],
      [true, {:activated_topic => @at, :start_date => Time.zone.local(2009,9,8,10,00), :duration =>  60}, "Questa lezione è in conflitto con la lezione di #{@at.topic.display_tooltip} di #{@at.teacher.full_name} (#{ref.time})", "Questa lezione è in conflitto con la lezione di #{@at.topic.display_tooltip} di #{@at.teacher.full_name} (#{ref.time}), la lezione di #{@atpiano.topic.display_tooltip} di #{@atpiano.teacher.full_name} (#{ref.time})", ]
    ]
    assert @at.reload
    [:new, :create].each do
      |m|
      midx = m == :new ? 2 : 3
      args.each do
		    |a|
		    assert ls = LessonSupport.new(a[0], Lesson.send(m, a[1]), a[midx])
		    assert_equal !ls.conflict, ls.lesson.verify_compatibility
        assert_equal ls.messages, ls.lesson.warnings, "method :#{m.to_s}, lesson #{ls.lesson.inspect}"
      end
    end
  end

  test "self conflict" do
    clear_all_lessons
		start_date = Time.zone.local(2009,9,8,10,00)
    [:new, :create].each do
      |m|
      assert l = Lesson.send(m, :activated_topic => @at, :start_date => start_date, :duration =>  60)
      assert l.valid?
		  assert !l.conflicts?
    end
    clear_all_lessons
		assert c = Lesson.create(:activated_topic => @at, :start_date => start_date, :duration => 60)
		assert c.valid?
		assert d = c.clone
		assert !d.conflicts?
    #
    # move it a bit further
    #
    sd2 = start_date.since(15.minutes)
    assert d.start_date = sd2
    assert !d.conflicts?
	end

  test "lesson filtering" do
    clear_all_lessons
    assert at1 = activated_topics(:informatica_year_one)
    assert at2 = activated_topics(:informatica_year_two)
    assert csy1 = course_starting_years(:tds_one)
    assert csy2 = course_starting_years(:tds_two)
    assert dstart = Time.zone.local(2009, 10, 19, 8, 0)
    assert dend   = Time.zone.local(2009, 10, 25, 20, 0)
    lessons = [
      assert(Lesson.create(:activated_topic => at1, :start_date => Time.zone.local(2009,10,18,10,0), :duration => 120)), # too early
      assert(Lesson.create(:activated_topic => at1, :start_date => Time.zone.local(2009,10,20,10,0), :duration => 120)),
      assert(Lesson.create(:activated_topic => at2, :start_date => Time.zone.local(2009,10,21,10,0), :duration => 120)),
      assert(Lesson.create(:activated_topic => at2, :start_date => Time.zone.local(2009,10,26,10,0), :duration => 120)), # too late
    ]
    should_be = 2
    #
    # let us filter with no filters
    #
    assert_equal should_be, Lesson.filtered(dstart, dend).size
    #
    # now let's filter by at1
    #
    assert filter = at1.class.name + '.' + at1.id.to_s
    assert_equal 1, Lesson.filtered(dstart, dend, filter).size
    #
    # now let's filter by csy1
    #
    assert filter = csy1.class.name + '.' + csy1.id.to_s
    assert_equal 1, Lesson.filtered(dstart, dend, filter).size
    #
    # now let's filter by teacher
    #
    assert teacher = users(:nicb)
    assert teacher.is_a?(Teacher)
    assert filter = teacher.class.name + '.' + teacher.id.to_s
    assert_equal 1, Lesson.filtered(dstart, dend, filter).size
    #
    # now let's filter by somebody who should not have these lessons
    #
    assert teacher = users(:neve)
    assert teacher.is_a?(Teacher)
    assert filter = teacher.class.name + '.' + teacher.id.to_s
    assert_equal 0, Lesson.filtered(dstart, dend, filter).size
    #
    # finally, let's try some botched filters to test resiliency
    #
    assert filter = 'BotchedClass' + '.' + -1.to_s
    assert_raise(Lesson::InvalidFilter) { Lesson.filtered(dstart, dend, filter) }
    assert filter = 'ActivatedTopic' + '.' + -1.to_s
    assert_raise(Lesson::InvalidFilter) { Lesson.filtered(dstart, dend, filter) }
  end

  test "time" do
    assert t = Time.zone.local(2009,8,25,10,0)
    assert l = Lesson.create(:activated_topic => @at, :start_date => t, :duration =>  120)
    assert should_be = t.hour.to_ss + ':' + t.min.to_ss + ' - ' + t.since(l.duration.minutes).hour.to_ss + ':' + t.since(l.duration.minutes).min.to_ss
    assert_equal should_be, l.time
  end

  test "duration vs end date" do
    assert t = Time.zone.local(2009,8,25,10,0)
    assert dur = 120 # minutes
    assert end_should_be = t.since(dur.minutes)
    assert l = Lesson.create(:activated_topic => @at, :start_date => t, :duration =>  dur)
    assert_equal end_should_be, l.end_date
  end

  test "start date and end date" do
    assert t = Time.zone.local(2009,8,25,10,0)
    assert dur = 120 # minutes
    assert end_should_be = t.since(dur.minutes)
    assert l = Lesson.create(:activated_topic => @at, :start_date => t, :duration =>  dur)
    assert_equal t, l.start_date
    assert_equal end_should_be, l.end_date
  end

  test "more of start date and end date" do
    assert t = Time.zone.local(2009,8,25,10,0)
    assert tclass = t.class
    assert dur = 120 # minutes
    assert end_should_be = t.since(dur.minutes)
    assert l = Lesson.create(:activated_topic => @at, :start_date => t, :duration =>  dur)
    assert l.valid?
    assert l.reload
    assert_equal t, l.start_date
    assert_equal end_should_be, l.end_date
    assert_equal tclass, l.start_date.class
    assert_equal tclass, l.end_date.class
    assert_equal t.zone, l.start_date.zone
    assert_equal end_should_be.zone, l.end_date.zone
  end

  test "update with duration" do
    assert sd = Time.zone.now.monday + 8.hours # make sure it's valid
    assert dur = 60
    assert ed = sd.since(dur.minutes)
    assert l = Lesson.create(:activated_topic => @at, :start_date => sd, :duration => dur)
    assert l.valid?
    assert_equal ed, l.end_date
    assert_equal dur, l.duration
    #
    # let's change dur
    #
    assert dur *= 2
    assert ed = sd.since(dur.minutes)
    assert l.update_attributes!(:duration => dur)
    assert_equal ed, l.end_date
    assert_equal dur, l.duration
    #
    # let's change end_date
    #
    assert dur += 30
    assert ed = sd.since(dur.minutes)
    assert l.update_attributes!(:end_date => ed)
    assert_equal ed, l.end_date
    assert_equal dur, l.duration
    #
    # let's do it with a hash argument
    #
    assert lh = { 'duration' => '30', 'start_date' => { 'start_date(1i)' => '2009', 'start_date(2i)' => '11', 'start_date(3i)' => '7', 'minute' => '30', 'hour' => '11' }}
    assert sd = Time.zone.create_from_hash(lh['start_date'])
    assert ed = sd.since(lh['duration'].to_i.minutes)
    assert l.update_attributes!(:duration => lh['duration'], :start_date => Time.zone.create_from_hash(lh['start_date']))
    assert_equal sd, l.start_date
    assert_equal ed, l.end_date
    assert_equal lh['duration'].to_i, l.duration
  end

  test "update with full data" do
		#
		# when updating attributes with full data, we end up having race
		# conditions. For these reason we want to test several time with
		# full updates to make sure we get it right
		#
		1.upto(500) do
			|n|
			assert extra_sd_fuzz = (3600 * rand()).round
      assert sd = Time.zone.now.monday + 8.hours + extra_sd_fuzz # make sure it's valid
      assert nominal_dur = 60
			assert extra_dur_fuzz = (nominal_dur * rand()).round - (nominal_dur/2.0).round
			assert dur = nominal_dur + extra_dur_fuzz
      assert ed = sd.since(dur.minutes)
      assert l = Lesson.create(:activated_topic => @at, :start_date => sd, :duration => dur)
      assert l.valid?
      assert_equal ed, l.end_date
      assert_equal dur, l.duration
      #
      # let's change dur
      #
      assert dur *= 2 + (15 * rand() - 7.5).round
      assert ed = sd.since(dur.minutes)
      assert l.update_attributes!(:duration => dur, :start_date => sd)
      assert_equal ed, l.end_date
      assert_equal dur, l.duration
			assert_equal sd, l.start_date
			assert l.update_attributes!(:duration => dur, :start_date => sd, :end_date => ed)
      assert_equal ed, l.end_date
      assert_equal dur, l.duration
			assert_equal sd, l.start_date
      #
      # let's change end_date
      #
      assert dur += 30 + (15 * rand() - 7.5).round
      assert ed = sd.since(dur.minutes)
      assert l.update_attributes!(:end_date => ed)
      assert_equal ed, l.end_date
      assert_equal dur, l.duration
			assert_equal sd, l.start_date
      assert l.update_attributes!(:end_date => ed, :start_date => sd)
      assert_equal ed, l.end_date
      assert_equal dur, l.duration
			assert_equal sd, l.start_date
      #
      # let's change start_date
      #
			assert sd += (extra_sd_fuzz / 2.0).round
      assert ed = sd.since(dur.minutes)
      assert l.update_attributes!(:start_date => sd)
			assert_equal ed, l.end_date, "#{n}: end_date failed; dur = #{dur}; attrs key sequence: #{l.attributes.keys.map { |k| k.to_s }.join(', ')}"
      assert_equal dur, l.duration, "#{n}: duration failed; dur = #{dur}; attrs key sequence: #{l.attributes.keys.map { |k| k.to_s }.join(', ')}"
			assert_equal sd, l.start_date, "#{n}: start_date failed; dur = #{dur}; attrs key sequence: #{l.attributes.keys.map { |k| k.to_s }.join(', ')}"
			assert l.update_attributes!(:end_date => ed, :start_date => sd)
			assert_equal ed, l.end_date, "#{n}: end_date failed; attrs key sequence: #{l.attributes.keys.map { |k| k.to_s }.join(', ')}"
      assert_equal dur, l.duration, "#{n}: duration failed; attrs key sequence: #{l.attributes.keys.map { |k| k.to_s }.join(', ')}"
			assert_equal sd, l.start_date, "#{n}: start_date failed; attrs key sequence: #{l.attributes.keys.map { |k| k.to_s }.join(', ')}"
			#
			# let's try by substituting attributes
			#
			assert sd += (3600 * rand()).round
			assert dur += (extra_dur_fuzz/2.0).round
			assert ed = sd + dur.minutes
			assert attrs = { 'end_date' => ed, 'start_date' => sd, 'description' => nil, 'place_id' => nil, }
			assert l.attributes = attrs
			assert_equal sd, l.start_date, "start_date failed; attrs key sequence: #{attrs.keys.map { |k| k.to_s }.join(', ')}"
			assert_equal ed, l.end_date, "end_date failed; attrs key sequence: #{attrs.keys.map { |k| k.to_s }.join(', ')}"
			assert_equal dur, l.duration, "duration failed; attrs key sequence: #{attrs.keys.map { |k| k.to_s }.join(', ')}"
			#
			# clean up
			#
			assert l.destroy
			assert l.frozen?
		end
  end

  test "clone" do
    clear_all_lessons
    assert lstart = Time.zone.now.monday + 10.hours
    assert ref =
    [
      Lesson.create(:activated_topic => @at, :start_date => lstart, :duration => 120),
      Lesson.create(:activated_topic => @at, :start_date => lstart + 2.days, :duration => 120),
    ]
    ref.each { |l| assert l.valid?; assert !l.cloned?; assert !l.new_record? }
    assert cl = ref[0].clone
    assert_nil cl.id
    assert_equal ref[0].id, cl.temp_clone_id
    assert cl.valid?
    assert cl.cloned?
    assert cl.new_record?
    assert_not_equal ref[1].id, cl.temp_clone_id
    cl.clone_attributes.keys.each { |k| assert_equal ref[0].send(k), cl.send(k) }
    cl.clone_attributes.keys.each { |k| assert_equal ref[0].send(k) == ref[1].send(k), ref[1].send(k) == cl.send(k) }
    [:created_at, :updated_at].each { |k| assert_not_equal ref[0].send(k), cl.send(k) }
    #
    assert cl.save
    assert cl.reload
    assert cl.valid?
    ref.each { |l| assert_not_equal l.id, cl.id }
    assert !cl.cloned?
  end

  test "update cloner" do
    clear_all_lessons
    assert lstart = Time.zone.now.monday + 10.hours
    assert dur = 120
    assert ref =
    [
      Lesson.create(:activated_topic => @at, :start_date => lstart, :duration => dur),
      Lesson.create(:activated_topic => @at, :start_date => lstart + 2.days, :duration => dur),
    ]
    ref.each { |l| assert l.valid?; assert !l.cloned? }
    assert cl = ref[0].clone
    assert cl.cloned?
    assert ed = ref[0].end_date
    #
    assert lstart_new = lstart + 1.hour
    assert dur_new = dur - 60
    assert cl.start_date = lstart_new
    assert cl.duration = dur_new
    assert cl.update_cloner!
    ref.each { |l| assert l.reload }
    assert_equal lstart_new, ref[0].start_date
    assert_equal ed, ref[0].end_date
    assert_equal dur_new, ref[0].duration
    assert_equal lstart + 2.days, ref[1].start_date
    assert_equal dur, ref[1].duration
  end

  test "cloned from query" do
    clear_all_lessons
    assert lstart = Time.zone.now.monday + 10.hours
    assert dur = 120
    assert ref =
    [
      Lesson.create(:activated_topic => @at, :start_date => lstart, :duration => dur),
      Lesson.create(:activated_topic => @at, :start_date => lstart + 2.days, :duration => dur/2),
    ]
    ref.each { |l| assert l.valid?; assert !l.cloned? }
    assert cl = ref[0].clone
    assert cl.cloned?
    assert cl.cloned_from?(ref[0])
    assert !cl.cloned_from?(ref[1])
  end

  test "lesson display rendering" do
    assert lstart = Time.zone.now.monday + 10.hours
    assert dur = 120
    assert l = Lesson.create(:activated_topic => @at, :start_date => lstart, :duration => dur)
    assert_equal Lesson::LessonRenderer, l.renderer.class
    assert_equal 'calendar/event/lesson', l.renderer.template
    # 2 px for bottom-top height should be removed
    assert_equal ((dur.to_f/l.cell_time.to_f)*l.row_height).round-2, l.height
  end

  test "lesson display prepare_data_set" do
    clear_all_lessons
    assert lstart = Time.zone.local(2009,11,14).monday + 8.hours
    assert dur = 120
    assert ref =
    [
      Lesson.create(:activated_topic => @at, :start_date => lstart, :duration => dur),
      Lesson.create(:activated_topic => @at, :start_date => lstart + 1.days, :duration => dur),
      Lesson.create(:activated_topic => @at, :start_date => lstart + 2.days, :duration => dur),
      Lesson.create(:activated_topic => @at, :start_date => lstart + 3.days, :duration => dur),
      Lesson.create(:activated_topic => @at, :start_date => lstart + 4.days, :duration => dur),
      Lesson.create(:activated_topic => @at, :start_date => lstart + 5.days, :duration => dur),
    ]
    assert lend = lstart + 5.days + 12.hours
    assert data_set = Lesson.prepare_data_set(lstart, lend)
    assert_equal 6, data_set.size
    data_set.each { |ds| assert_equal 1, ds.size }
    assert d = Calendar::Display::Week::Display.new(lstart)
    assert d.add_data_set(data_set)
    assert r = d.renderer
    assert_equal Calendar::Display::Week::Display::DisplayRenderer, r.class
    assert_equal 7, r.object.size
    assert_equal Calendar::Display::Week::RowHeader::RowHeaderRenderer, r.object[0].class
    r.object[1..r.object.size-1].each do
      |d|
      assert_equal Calendar::Display::Week::Day::DayRenderer, d.class
      assert_equal Calendar::Display::Week::Day, d.object[:column].class
      assert_equal Lesson::LessonRenderer, d.object[:events][0].class
    end
  end

  test "operator ==" do
    assert l1 = Lesson.new(:activated_topic => @at, :start_date => Time.zone.local(2009,8,25,10,00), :duration =>  120)
    assert l1.valid?
    assert l2 = Lesson.new(:activated_topic => @at, :start_date => Time.zone.local(2009,8,26,10,00), :duration =>  120)
    assert l2.valid?
    class FakeObject; end
    assert f1 = FakeObject.new
    assert l1 == l1
    assert l1 != l2
    assert l1 != f1
  end

private

  def clear_all_lessons
    Lesson.all.each { |l| assert l.destroy; assert l.frozen? }
  end

end
