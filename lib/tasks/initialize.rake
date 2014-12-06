#
# $Id$
#
RAILS_ENV ||= 'production'

namespace :db do
  desc "Initialize the #{RAILS_ENV} database with fixtures from db/initialize"
  task :initialize => :environment do
    require 'active_record/fixtures'
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    Dir.glob(File.join(RAILS_ROOT, 'db', 'initialize', '*.{yml,csv}')).each do
      |fixture_file|
      puts("Loading fixture #{fixture_file}")
      Fixtures.create_fixtures('db/initialize', File.basename(fixture_file, '.*'))
    end
  end
end
