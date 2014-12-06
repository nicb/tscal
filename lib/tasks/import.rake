#
# $Id: import.rake 176 2009-11-17 05:28:54Z nicb $
#
# This tasks sets the proper Course constants for Conservatorio Pollini
# if they are already in place and correct, they go untouched
#

namespace :db do

  namespace :import do

	  desc "Set the proper Course constants for Conservatorio Pollini; if they are already in place they go untouched"
	  task :courses => :environment do
	
			COURSES =
			[
	      { :name => 'Tecnico di Sala di Registrazione', :acronym => 'TS', :duration => 3 },
	      { :name => 'Biennio di Didattica', :acronym => 'BD', :duration => 2 },
	      { :name => 'Metodologie e Tecniche Musicali per le Disabilità', :acronym => 'DS', :duration => 3 },
	      { :name => 'Corsi Musicali di Base', :acronym => 'B', :duration => 3 },
	    ]
			
			COURSES.each do
			  |args|
			  printf("Creating \"#{args[:name]}\" with acronym '#{args[:acronym]}'...")
        c = Course.find_by_acronym(args[:acronym])
        if c && c.valid?
          c.update_attributes!(args)
        else
			    c = Course.create(args)
			    raise(ActiveRecord::ActiveRecordError, "Course \"#{c.name}\" (#{c.acronym}) was not saved (#{c.errors.full_messages.join(', ')})") unless c.save
        end
			  puts(' Done.')
			end
	
	  end

    require "#{RAILS_ROOT}" + '/config/environment'
    require 'extensions/string'
    require 'user'

    desc "Import all AA 2009 topics, courses, teachers, etc."
    task :all2009 => [:environment, :courses] do

      include Import::Topics::Driver

      import_and_parse do
        |ad|
        puts("Importing Topic \"#{ad[:topic][:name]}\" (#{ad[:topic][:name].create_acronym}) (teacher: #{ad[:teacher][:full_name]})")
      end

    end

  end

end
