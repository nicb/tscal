#
# $Id: string.rb 176 2009-11-17 05:28:54Z nicb $
#

class String

  MAXIMUM_ACRONYM_SIZE = 7
  DEFAULT_ACRONYM_SIZE = 4

  UNCONVENTIONAL_ACRONYMS =
  {
    'Elettroacustica' => 'EA',
    'Elettroacustica - Tecniche di Ripresa Microfonica' => 'EATRM',
  }

  def create_acronym
    if UNCONVENTIONAL_ACRONYMS.has_key?(self)
      result = UNCONVENTIONAL_ACRONYMS[self]
    else
      members = split_in_relevant_parts { |p| p if (p.size > DEFAULT_ACRONYM_SIZE && p !~ /(dell[aoe]|degli)/) }
	    if members.size == 1
	      result = members[0].upcase[0..DEFAULT_ACRONYM_SIZE-1]
	    else
	      result = members.map { |m| m[0].chr }.join('').upcase[0..MAXIMUM_ACRONYM_SIZE-1]
	    end
    end
    return result
  end

  def capitalize_all
    members = split_in_relevant_parts { |p| (p.size > DEFAULT_ACRONYM_SIZE && p !~ /(dell[aoe]|degli)/) ? p.capitalize : p }
    return members.join(' ')
  end

private

  def cleansed_string
    return gsub(/'/, ' ').gsub("\n", '').sub(/\s*\(.*\)\s*$/, '').sub(/\s*[0-9]+\s*$/,'')
  end

  def split_in_relevant_parts
    cleansed = cleansed_string
    parts = cleansed.split(/[\s']+/)
    members = []
    parts.each do
      |p|
      el = yield(p)
      members << el
    end
    return members.compact
  end

end
