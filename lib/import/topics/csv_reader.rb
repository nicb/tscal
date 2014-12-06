#
# $Id: csv_reader.rb 176 2009-11-17 05:28:54Z nicb $
#

require 'csv'

module Import

	module Topics
	
	  module Importer
	
			class CsvReader
			  attr_reader :datafile, :data
			
			  def initialize(df)
			    @datafile = df
			    @data = []
			    reader = CSV.open(@datafile, 'r')
			    reader.map { |l| @data << l }
			  end
	
	    private
	
	      # ["Sigla corso", "Tipologia", "Insegnamenti", "TipLez", "A/S", "Ore",
	      #  "Cfa", "Anno", "1sm", "2sm", "docenti", "In MO", "Pagate", " Lordo
	      #  docente", " Netto docente", " Lordo scuola"]
	      COLUMN_MAP = 
	      [
	        "course[:acronym]",
	        {"activated_topic[:teaching_typology]" => { :method => 'teaching_typology_remap' }},
	        "topic[:name]",
	        "activated_topic[:delivery_type]",
	        "dummy",
	        {"activated_topic[:duration]" => { :method => 'duration_remap' }},
	        "activated_topic[:credits]",
	        {"activated_topic[:semester_start]" => { :method => 'semester_remap', :columns => 3 }},
	        {"teacher[:full_name]" => { :method => :teacher_name_remap }},
	        'teacher[:teacher_typology]',
	        'activated_topic[:hours_in_mo]',
	        'activated_topic[:hours_paid]',
	        'activated_topic[:teacher_gross]',
	        'activated_topic[:teacher_net]',
	        'activated_topic[:school_gross]',
	      ]
	
	      def column_map
	        return COLUMN_MAP
	      end
	
	    public
	
	      def row(idx)
	        myrow = data[idx]
	        activated_topic = {}; topic = {}; teacher = {}; course = {}; dummy = nil;
	        cidx = cmidx = 0
	        row_size = myrow.size
	        while cidx < row_size
	          c = myrow[cidx]
	          cmap = column_map[cmidx]
	          if cmap.is_a?(Hash)
	            key = cmap.keys.first
	            hd = cmap[key]
	            if hd.has_key?(:columns)
	              c_a = myrow[cidx..(cidx+hd[:columns]-1)]
	              unless c_a.blank?
	                line = "#{key} = send(:#{hd[:method]}, #{c_a.inspect}, #{idx})" 
	                eval(line)
	              end
	              cidx += hd[:columns]
	            else
	              unless c.blank?
	                line = "#{key} = send(:#{hd[:method]}, \"#{c}\", #{idx})"
	                eval(line)
	              end
	              cidx += 1
	            end
	          else
	            unless c.blank?
		            d = c.gsub(/"/, '')
		            line = "#{cmap} = \"#{d}\""
		            eval(line)
	            end
	            cidx += 1
	          end
	          cmidx += 1
	        end
	        return { :activated_topic => activated_topic, :topic => topic, :teacher => teacher, :course => course }
	      end
	
	    private
			
	      def course_year(string, idx)
	        s = string.gsub(/\s*/,'').split('-')
	        m = { 'I' => 1, 'II' => 2, 'III' => 3 }
	        return m[s[0]]
	      end
	
	      class InvalidSemester < ArgumentError
	      end
	
	      def semester_remap(sem_array, idx)
	        cy = course_year(sem_array[0], idx)
	        sem = case
	                when sem_array[1] && sem_array[2]  : 1
	                when sem_array[1] && !sem_array[2] : 1
	                when !sem_array[1] && sem_array[2] : 2
	                else raise(InvalidSemester, "The semester data at row #{idx} is invalid")
	             end
	        return ((cy - 1) * 2) + sem
	      end
	
	      def teacher_name_remap(string, idx)
	        name = string.strip.gsub(/\s*\(.*\)/, '')
	        name = case
	                 when name =~ /UNIPD/ : 'Docente Altra Facoltà'
	                 when name =~ /^Fac.*Logopedia$/ : 'Docente Altra Facoltà'
	                 when name =~ /esterno/ : 'Docente Esterno'
	                 when name =~ /interno/ : 'Docente Interno'
	                 when name =~ /[Tt]irocinio/ : 'Docente Tirocinante'
	                 else name
	               end
	        return name
	      end
	
	      def tt_remap(da, idx)
	        result =  { :in_mo => da[0], :paid => da[1], :teacher_gross => da[2], :teacher_net => da[3], :school_gross => da[4] }
	        return result
	      end
	
	      def teaching_typology_remap(tt, idx)
	        map = { 'caratt.' => 'C', 'affine' => 'A', 'base' => 'B' }
	        return map[tt]
	      end
	
	      def duration_remap(dur, idx)
	        return dur.to_i
	      end
	
			end
	
	  end
	
	end

end
