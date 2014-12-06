#
# $Id$
#
module LessonHelper

  DEFAULT_LESSON_HOUR_START = 8
  DEFAULT_LESSON_HOUR_END = 19

  include ActionView::Helpers::DateHelper

  def select_lesson_hour(hour, options = {}, html_options = {})
    hour = condition_hour(hour)
    str = select_hour(hour, options, html_options)
    str.gsub!(/<option value="0[0-7]">0[0-7]<\/option>/, '') # remove all hours [0..7]
    str.gsub!(/<option value="2[0-4]">2[0-4]<\/option>/, '') # remove all hours [20..24]
    str.gsub!(/\n\n*/, "\n") # remove multiple blank lines
    return str
  end

  def lesson_time_select(on, method, options = {}, html_options = {})
    t = options.has_key?(:default) && options[:default].is_a?(Time) ?  options[:default] : Time.zone.now
    hour = condition_hour(t.hour)
    # options.update(:default => Time.zone.local(t.year, t.month, t.day, hour, t.min, t.sec), :ignore_date => true)
    options.update(:default => Time.zone.local(t.year, t.month, t.day, hour, t.min, t.sec))
    str = time_select(on, method, options, html_options)
    str.gsub!(/\n/, '@@') # temporarily substitute newlines
    str.sub!(/(<select.*\(4i\)\]">)((@@<option value="0[0-7]">0[0-7]<\/option>)*)/, '\1') # remove all hours [0..7]
    str.sub!(/(@@<option value="2[0-3]">2[0-3]<\/option>)+/, '') # remove all hours [20..24]
    str.gsub!(/@@/, "\n") # put the newlines back in place
    return str
  end

private

  def condition_hour(hour)
    result = case 
      when hour < DEFAULT_LESSON_HOUR_START : DEFAULT_LESSON_HOUR_START
      when hour > DEFAULT_LESSON_HOUR_END   : DEFAULT_LESSON_HOUR_END
      else hour
    end
    return result
  end

end
