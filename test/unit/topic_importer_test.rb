#
# $Id: topic_importer_test.rb 290 2012-07-31 01:45:43Z nicb $
#
require 'test/test_helper'
require 'topics'
require 'string'

class TopicImporterTest < ActiveSupport::TestCase

  fixtures :courses

  include Import::Topics::Driver

  def test_import
    yml_file = File.open('tmp/topics_import.yml', 'w')
    import_csv { |ad| yml_file.puts(YAML.dump(ad)) }
    yml_file.close
  end

  def test_import_and_parse
    #
    assert sizes = object_counts
    #
    import_and_parse
    #
    sizes.each do
      |k, v|
      assert k.all.size >= v, "for #{k.name} class size does not match (#{k.all.size} !>= #{v})"
    end
  end

  def test_reimport_and_parse
    #
    import_and_parse
    #
    assert sizes = object_counts
    #
    import_and_parse # once again, numbers should not change
    #
    sizes.each do
      |k, v|
      assert k.all.size == v, "for #{k.name} class size does not match (#{k.all.size} != #{v})"
    end
  end

private

  def object_counts
    {
      Course => Course.count,
      Teacher => Teacher.count,
      Topic => Topic.count,
      CourseStartingYear => CourseStartingYear.count,
      ActivatedTopic => ActivatedTopic.count,
    }
  end

end
