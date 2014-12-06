#
# $Id: datetime.rb 297 2012-11-02 21:34:54Z nicb $
#

class ActiveSupport::TimeWithZone

  WDAY_MAP = {
    "Domenica" => 0,
    "Lunedì" => 1,
    "Martedì" => 2,
    "Mercoledì" => 3,
    "Giovedì" => 4,
    "Venerdì" => 5,
    "Sabato" => 6,
  } unless defined?(WDAY_MAP)

  class WdayNotFound < StandardError
  end
  
  class BadWdayArgument < StandardError
  end
  
  class << self

    def italian_to_wday(italian_wday)
      return WDAY_MAP[italian_wday]
    end
    
    def italian_wday_names
      return WDAY_MAP.keys.sort {|a, b| WDAY_MAP[a] <=> WDAY_MAP[b]}
    end

    def wdays(italian_wdays)
      return italian_wdays.map{|iw| italian_to_wday(iw)}
    end

  end
  
  def iwday
    rwday = WDAY_MAP.invert
    return rwday[wday]
  end
  
  def blacklisted?
    d = BlacklistedDate.first(:conditions => ['blacklisted like ?', "#{self.to_date.to_s}%"])
    return d && d.valid? ? true : false
  end
  
  def form_select_options(extra_options = {})
    result = { :start_year => self.year - 1, :order => [:day, :month, :year], :use_month_names => %w(Gennaio Febbraio Marzo Aprile Maggio Giugno Luglio Agosto Settembre Ottobre Novembre Dicembre), :default => self }
    result.update(extra_options)
    return result
  end

  def next_available_day(italian_wdays)
    raise(BadWdayArgument, "Inserisci un giorno della settimana") if italian_wdays.blank?
    wantedwdays = self.class.wdays(italian_wdays)
    mywday = self.wday
    delta = 0
    result = nil
    until result
      flag = false
      wantedwdays.each do 
				|wd|
				if mywday == wd
				  flag = true
				  break
				end
      end
      if flag == true
        result = self + delta.days
        result = result.blacklisted? ? nil : result
      end
      mywday += 1
      mywday %= 7
      delta += 1
    end
    return result
  end

  def floor
    dct = Calendar::Display::Week::Methods::DEFAULT_CELL_TIME
    curt = lastt = Time.zone.local(self.year,self.month,self.day,self.hour,0,0)
    while curt <= self
      lastt = curt
      curt += dct.minutes
    end
    return lastt
  end

  #
  # 'monday' needs to be rewritten because we want to round the sunday to the
  # incoming week, not to the past one. So we add one day and round to monday.
  # Saturday will round to last monday, but sunday will round to the next.
  #
  def monday
    return (self + 1.day).beginning_of_week
  end
end
