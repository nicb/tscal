#
# $Id: user.rb 212 2010-01-29 06:13:04Z nicb $
#
require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base

  class <<self

	  def authenticate(login, pass)
	    first(:conditions => ["login = ? AND password = ?", login, sha1(pass)])
	  end  

	  def sha1(pass)
	    Digest::SHA1.hexdigest("change-me--#{pass}--")
	  end

  end

public

  def authorized?
    return false
  end

  def change_password(pass)
    update_attribute "password", self.class.sha1(pass)
  end
    
  def full_name
    return first_name + ' ' + last_name
  end

  before_create :crypt_password

protected
  
  def crypt_password
    write_attribute("password", self.class.sha1(password))
  end

  validates_length_of :login, :within => 3..40
  validates_length_of :password, :within => 5..40
  validates_presence_of :login, :password, :password_confirmation, :first_name, :last_name, :type, :email
  validates_uniqueness_of :login, :on => :create
  validates_confirmation_of :password, :on => :create     
end

class Admin < User

  def authorized?
    return true
  end

end

class Teacher < User
  has_many :activated_topics, :dependent => :destroy
  has_many :topics, :through => :activated_topics

public
  #
  # option group methods
  #

  include OptionGroupHelper

  class <<self

	  def group_label
	    return 'Docenti'
	  end

    def group
      return all.sort { |a, b| a.last_name <=> b.last_name }
    end

  end

  def option_value
    return full_name
  end

  #
  # extra info
  #

  TYPOLOGIES = { 'I' => 'Interno', 'E' => 'Esterno' }
  DEFAULT_TYPOLOGY = 'I'

  class <<self

    def teacher_typology_selector
      return TYPOLOGIES.keys.sort.reverse.map { |k| [TYPOLOGIES[k], k] }
    end

  end

  def teacher_typology_extended
    return TYPOLOGIES[read_attribute(:teacher_typology)]
  end

  #
  # Calendar Filtering management
  #

  include LessonFilteringHelper

end
