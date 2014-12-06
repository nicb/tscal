#
# $Id: lesson_helper_test.rb 192 2009-12-14 22:49:48Z nicb $
#
require 'test/test_helper'

class LessonHelperTest < ActiveSupport::TestCase

  include LessonHelper

  def setup
    @min_should_be = "<select id=\"date_hour\" name=\"date[hour]\">\n<option selected=\"selected\" value=\"08\">08</option>\n<option value=\"09\">09</option>\n<option value=\"10\">10</option>\n<option value=\"11\">11</option>\n<option value=\"12\">12</option>\n<option value=\"13\">13</option>\n<option value=\"14\">14</option>\n<option value=\"15\">15</option>\n<option value=\"16\">16</option>\n<option value=\"17\">17</option>\n<option value=\"18\">18</option>\n<option value=\"19\">19</option>\n</select>\n"
    @max_should_be = "<select id=\"date_hour\" name=\"date[hour]\">\n<option value=\"08\">08</option>\n<option value=\"09\">09</option>\n<option value=\"10\">10</option>\n<option value=\"11\">11</option>\n<option value=\"12\">12</option>\n<option value=\"13\">13</option>\n<option value=\"14\">14</option>\n<option value=\"15\">15</option>\n<option value=\"16\">16</option>\n<option value=\"17\">17</option>\n<option value=\"18\">18</option>\n<option selected=\"selected\" value=\"19\">19</option>\n</select>\n"
    @noon_should_be = "<select id=\"date_hour\" name=\"date[hour]\">\n<option value=\"08\">08</option>\n<option value=\"09\">09</option>\n<option value=\"10\">10</option>\n<option value=\"11\">11</option>\n<option selected=\"selected\" value=\"12\">12</option>\n<option value=\"13\">13</option>\n<option value=\"14\">14</option>\n<option value=\"15\">15</option>\n<option value=\"16\">16</option>\n<option value=\"17\">17</option>\n<option value=\"18\">18</option>\n<option value=\"19\">19</option>\n</select>\n"
  end

  test "select_lesson_hour" do
    0.upto(7) do
      |h|
      assert_equal @min_should_be, select_lesson_hour(h)
    end
    20.upto(23) do
      |h|
      assert_equal @max_should_be, select_lesson_hour(h)
    end
    assert_equal @noon_should_be, select_lesson_hour(12)
  end

  test "lesson_time_select" do
    #
    # FIXME: we don't know very well what to do to test this...
    #
    assert str = lesson_time_select('test', 'test')
    should_be_common = "<input id=\"test_test_1i\" name=\"test[test(1i)]\" type=\"hidden\" value=\"2009\" />\n<input id=\"test_test_2i\" name=\"test[test(2i)]\" type=\"hidden\" value=\"11\" />\n<input id=\"test_test_3i\" name=\"test[test(3i)]\" type=\"hidden\" value=\"26\" />\n<select id=\"test_test_4i\" name=\"test[test(4i)]\">\n<option selected=\"selected\" value=\"08\">08</option>\n<option value=\"09\">09</option>\n<option value=\"10\">10</option>\n<option value=\"11\">11</option>\n<option value=\"12\">12</option>\n<option value=\"13\">13</option>\n<option value=\"14\">14</option>\n<option value=\"15\">15</option>\n<option value=\"16\">16</option>\n<option value=\"17\">17</option>\n<option value=\"18\">18</option>\n<option value=\"19\">19</option>\n</select>\n : <select id=\"test_test_5i\" name=\"test[test(5i)]\">\n<option selected=\"selected\" value=\"00\">00</option>\n<option value=\"15\">15</option>\n<option value=\"30\">30</option>\n<option value=\"45\">45</option>\n</select>\n"
    0.upto(7) do
      |h|
      t = Time.zone.local(2009, 11, 26)
      t = Time.zone.local(t.year, t.month, t.day, h, t.min)
      assert str = lesson_time_select('test', 'test', t.form_select_options(:minute_step => 15))
      assert_equal should_be_common, str
    end
  end

end
