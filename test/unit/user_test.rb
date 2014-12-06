require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  
  def setup
    assert @bob = Admin.create(:login => 'this_bob', :first_name => 'Robert',
                            :last_name => 'Tester', :password => 'testtesttest',
                            :email => 'nobody@nowhere.com',
                            :password_confirmation => 'testtesttest')
    assert @bob.valid?, "User #{@bob.login} is not valid: #{@bob.errors.full_messages.join(', ')}"
    assert @longbob = Admin.create(:login => 'this_longbob', :first_name => 'Robert',
                            :last_name => 'Long', :password => 'longtest',
                            :email => 'nobody@nowhere.com',
                            :password_confirmation => 'longtest')
    assert @longbob.valid?, "User #{@longbob.login} is not valid: #{@longbob.errors.full_messages.join(', ')}"
    assert @standard_args = { :email => 'nobody@nowhere.com', :last_name => 'Login', :first_name => 'Good' }
  end
    
  def test_auth  
    assert_equal  @bob, User.authenticate("this_bob", "testtesttest")    
    assert_nil    User.authenticate("nonbob", "test")

  end


  def test_passwordchange
        
    @longbob.change_password("nonbobpasswd")
    assert_equal @longbob, User.authenticate("this_longbob", "nonbobpasswd")
    assert_nil   User.authenticate("this_longbob", "longtest")
    @longbob.change_password("longtest")
    assert_equal @longbob, User.authenticate("this_longbob", "longtest")
    assert_nil   User.authenticate("tnis_longbob", "nonbobpasswd")
        
  end
  
  def test_disallowed_passwords

    u = Teacher.new(@standard_args)
    u.login = "tnis_nonbob"

    u.password = u.password_confirmation = "tiny"
    assert !u.save     
    assert u.errors.invalid?('password')

    u.password = u.password_confirmation = "hugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehuge"
    assert !u.save     
    assert u.errors.invalid?('password')
        
    u.password = u.password_confirmation = ""
    assert !u.save    
    assert u.errors.invalid?('password')
        
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save     
    assert u.errors.empty?
        
  end
  
  def test_bad_logins

    u = Teacher.new(@standard_args)
    u.password = u.password_confirmation = "bobs_secure_password"

    u.login = "x"
    assert !u.save     
    assert u.errors.invalid?('login')
    
    u.login = "hugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhug"
    assert !u.save     
    assert u.errors.invalid?('login')

    u.login = ""
    assert !u.save
    assert u.errors.invalid?('login')

    u.login = "okbob"
    assert u.save  
    assert u.errors.empty?
      
  end


  def test_collision
    u = Teacher.new(@standard_args)
    u.login      = "existingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
    u = Teacher.new(@standard_args)
    u.login      = "existingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
    assert !u.save
    assert !u.valid?
  end


  def test_create
    u = Teacher.new(@standard_args)
    u.login      = "nonexistingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
      
    assert u.save  
    
  end
  
  def test_sha1
    u = Teacher.new(@standard_args)
    u.login      = "nonexistingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
        
    assert_equal '98740ff87bade6d895010bceebbd9f718e7856bb', u.password
    
  end

  def test_type_upgrade
    passwd = "bobs_secure_password"
    @standard_args.update(:login => 'really_an_admin', :password => passwd, :password_confirmation => passwd)
    assert u = Teacher.create(@standard_args)
    assert u.valid?
    assert u.is_a?(Teacher)
    #
    # we want to upgrade the user to be an Admin
    #
    assert u.type = Admin.name
    assert u.save
    assert_raise(ActiveRecord::RecordNotFound) { u.reload }
    assert a = Admin.find_by_login('really_an_admin')
    assert a.is_a?(Admin)
    #
    # what if we don't know what type he is?
    #
    assert u = User.find_by_login('really_an_admin')
    assert u.is_a?(Admin)
  end

  def test_type_downgrade
    passwd = "bobs_secure_password"
    @standard_args.update(:login => 'really_a_teacher', :password => passwd, :password_confirmation => passwd)
    assert u = Admin.create(@standard_args)
    assert u.valid?
    assert u.is_a?(Admin)
    #
    # we want to upgrade the user to be an Admin
    #
    assert u.type = Teacher.name
    assert u.save
    assert_raise(ActiveRecord::RecordNotFound) { u.reload }
    assert t = Teacher.find_by_login('really_a_teacher')
    assert t.is_a?(Teacher)
    #
    # what if we don't know what type he is?
    #
    assert u = User.find_by_login('really_a_teacher')
    assert u.is_a?(Teacher)
  end

  def test_querying_authentication
    assert @bob.valid?
    assert @bob.authorized?
    #
    assert t = Teacher.create(:login => 'test_teacher', :first_name => 'Test',
                            :last_name => 'Teacher', :password => 'testtesttest',
                            :email => 'teacher@nowhere.com',
                            :password_confirmation => 'testtesttest')
    assert t.valid?
    assert !t.authorized?
  end

  def test_teacher_typology
    assert ti = Teacher.create(:login => 'ijizz', :first_name => 'Test',
                               :last_name => 'Teacher', :password => 'testtesttest',
                               :email => 'teacher@nowhere.com',
                               :password_confirmation => 'testtesttest',
                               :teacher_typology => 'I')
    assert ti.valid?
    assert te = Teacher.create(:login => 'ijizz2', :first_name => 'Test',
                               :last_name => 'Teacher', :password => 'testtesttest',
                               :email => 'teacher@nowhere.com',
                               :password_confirmation => 'testtesttest',
                               :teacher_typology => 'E')
    assert te.valid?
    assert_equal 'Interno', ti.teacher_typology_extended
    assert_equal 'Esterno', te.teacher_typology_extended
  end

  def test_teacher_typology_selector
    should_be = [['Interno', 'I'], ['Esterno', 'E']]
    assert_equal should_be, Teacher.teacher_typology_selector
  end

end
