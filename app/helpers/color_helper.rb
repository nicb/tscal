#
# $Id: color_helper.rb 155 2009-11-08 02:31:51Z moro $
#
require 'color/palette/monocontrast'

module ColorHelper

	def self.included(base)
		base.extend ClassMethods
	end

	module ClassMethods
#		qua dentro metodi di classe
		COLORS = [
			Color::RGB::Red,
			Color::RGB::Lime,
			Color::RGB::Blue,
			Color::RGB::MediumVioletRed,
			Color::RGB::DarkOrange,
			Color::RGB::Yellow,
			Color::RGB::DarkOrchid,
			Color::RGB::NavajoWhite,
			Color::RGB::LightSeaGreen,
			Color::RGB::Silver,
			Color::RGB::Salmon,
			Color::RGB::DarkGreen,
			Color::RGB::DarkBlue
		]
		class ColorNotFound < StandardError
		end

		def choose_color
			found = nil
			COLORS.each do
				|c|
				found_obj = find_all_by_color(c.html)
				found = c
				found_obj.each do
					|f|
					found = nil unless found_obj.old?
				end
				break if found
			end
			raise(ColorNotFound) unless found
			return found
		end
	end
#qui sotto metodi di istanza
end


