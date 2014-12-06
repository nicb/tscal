#
# $Id: report_helper.rb 298 2012-11-03 14:34:29Z nicb $
#
module ReportHelper

  def course_selector
    courses = Course.all(:order => 'acronym')
    result = []
    courses.each { |c| result << [c.acronym, c.id.to_s] }
    return blanked_selection(result)
  end

  def teaching_typology_selector
    return blanked_selection(CourseTopicRelation.teaching_typology_selector)
  end

  def delivery_type_selector
    return blanked_selection(ActivatedTopic.delivery_type_selector)
  end

  def activation_selector
    keys = [ 'A', 'S' ]
    return blanked_selection(keys.map { |k| [k, k] })
  end

  def year_selector
    return blanked_selection(ActivatedTopic.currently_active_topics.map { |at| at.all_roman_years }.sort.uniq.map { |k| [k, k] })
  end

  def semester_selector
    keys = [ '1sem', '2sem' ]
    return blanked_selection(keys.map { |k| [k, k] })
  end

  def teacher_selector
    return blanked_selection(Teacher.all(:order => 'last_name').map { |t| [t.last_name, t.id.to_s] })
  end

  def teacher_typology_selector
    return blanked_selection(Teacher::TYPOLOGIES.keys.map { |k| [k, k] })
  end

private

  def blanked_selection(to_be_returned)
    return to_be_returned.unshift(['', '-1'])
  end

end
