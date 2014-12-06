#
# $Id: classroom_test.rb 66 2009-04-30 15:09:05Z moro $
#
require 'test/test_helper'

class ClassroomTest < ActiveSupport::TestCase

  fixtures :places

  def setup
    assert @place=Place.find_by_name("eremitani")
    assert @place2=Place.find_by_name("bertacchi")
  end

  def test_creation_destroy
    assert c = Classroom.create(:name => "aula 4", :place => @place2)
    assert c.valid?
    
    c.destroy
    assert c.frozen?
  end

  def test_presence_of
    assert c = Classroom.create()
    assert !c.valid?

    assert c = Classroom.create(:name => "aula 4")
    assert !c.valid?

    assert c = Classroom.create(:place => @place)
    assert !c.valid?
  end

  def test_uniqueness
    assert c_all = Classroom.all
    assert c_all.each{|c| c.destroy}
    assert c = Classroom.create(:name => "aula 4", :place => @place2)
    assert c.valid?
    assert c1 = Classroom.create(:name => "aula 5", :place => @place2)
    assert c1.valid?
    assert c2 = Classroom.create(:name => "aula 4", :place => @place)
    assert c2.valid?
    assert c3 = Classroom.create(:name => "aula 4", :place => @place)
    assert !c3.valid?
  end

end
