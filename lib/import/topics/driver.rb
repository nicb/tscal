#
# $Id: driver.rb 290 2012-07-31 01:45:43Z nicb $
#

require 'yaml'

module Import

	module Topics
	
	  module Driver
	
	    include Topics::Parser
	
	    DATA_FILE = File.dirname(__FILE__) + '/../../../db/import/Elenco insegnamenti trienni 2009-10.csv'
	    DATA_ROW_START = 2
	
	    class DataImportError < StandardError
	    end
	
	    def import_csv
		    csv = Topics::Importer::CsvReader.new(DATA_FILE)
	      begin
		      linenum = 0
		      DATA_ROW_START.upto(csv.data.size-1) do
		        |i|
		          linenum = i
              if csv.data[i][0]
		            analyzed_data = csv.row(i) 
	              yield(analyzed_data)
              end
		      end
#      rescue
#         raise(DataImportError, "Error at line #{linenum} (#{csv.row(linenum).inspect}): #{$!}")
	      end
	    end
	
	    def import_and_parse
	      import_csv do
	        |ad|
	        parse(ad)
	        yield(ad) if block_given?
	      end
	    end
	
	  end
	
	end

end
