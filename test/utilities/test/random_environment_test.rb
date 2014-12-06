#
# $Id: random_environment_test.rb 292 2012-08-23 16:26:37Z nicb $
#
require 'test/test_helper'
require 'test/utilities/random'

class RandomEnvironmentTest < ActiveSupport::TestCase

	fixtures :users

  include Test::Utilities::RandomEnvironment

	def setup
		assert @teacher = users(:costa)
		#
		# @teacher.valid? assertions will fail here because they require password
		# confirmation. However, other than that it is a perfectly valid model so
		# we don't particularly care about it and we use it just the same.
		#
	end

	test "random environment" do
		assert should_be = results_should_be
		assert num_of_ctr_links = random_environment(@teacher)
		assert should_be.update(:ctrs => num_of_ctr_links)
		check_results(should_be)
	end

	test "random environment with different options" do
		assert different_options =
					 [
							{ 'num_courses' => 2, 'year_start' => CourseStartingYear::CURRENT_AA - 1, 'year_end' => CourseStartingYear::CURRENT_AA, 'num_topics' => 2 },
							{ 'num_courses' => 8, 'year_start' => CourseStartingYear::CURRENT_AA - 8, 'year_end' => CourseStartingYear::CURRENT_AA, 'num_topics' => 8 },
					 ]
		different_options.each do
			|opts|
			assert should_be = results_should_be(opts)
			assert num_of_ctr_links = random_environment(@teacher, opts)
		  assert should_be.update(:ctrs => num_of_ctr_links)
			check_results(should_be)
		end
	end

private

	def results_should_be(opts = nil)
		assert options = opts ? opts : DEFAULT_ENVIRONMENT_OPTIONS.dup
		assert res = {}
		assert nyears = options['year_end'] - options['year_start'] + 1
		assert csys = options['num_courses'] * nyears
		assert ats = options['num_topics']
		assert ctrs = ats * csys
		assert res.update(:courses => options['num_courses'],
											:years => nyears,
											:topics => options['num_topics'],
											:csys => csys,
											:ats => ats,
											:ctrs => ctrs)
		res
	end

	def check_results(should_be)
		assert_equal should_be[:courses], Course.count
		assert_equal should_be[:topics], Topic.count
		assert_equal should_be[:csys], CourseStartingYear.count
		assert_equal should_be[:ats], ActivatedTopic.count
		assert_equal should_be[:ctrs], CourseTopicRelation.count
	end

end
