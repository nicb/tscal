#
# $Id: place_test.rb 237 2010-03-08 11:10:50Z moro $
#
 require 'test/test_helper'

class PlaceTest < ActiveSupport::TestCase

#  fixtures :classrooms

  def setup
    assert @classroom = Classroom.first
		@street = "via Roma"
		@number = "35/a"
		@url		 = "www.url.com"
		@city	 = "Padova"
		@name	= "Roma"
  end

  def test_creation_destroy
    assert p = Place.create(:name => @name, :street => @street, :number => @number, :url => @url, :city => @city)
    assert p.valid?
    p.destroy
    assert p.frozen?
  end

  def test_validation_presence_of
		# we can create a place without url
		assert p1 = Place.create(:name => @name, :street => @street, :number => @number, :city => @city)
		assert p1.valid?
		# but we can't create place without all the other field
		assert args = {:name => @name, :street => @street, :number => @number, :city => @city}		
		args.keys.each do
      |k|
      a = args.dup
      a.delete(k)
      assert p = Place.create(a)
      assert !p.valid?
    end
  end

  def test_validation_uniqueness
    assert p = Place.create(:name => @name, :street => @street, :number => @number, :url => @url, :city => @city)
    assert p.valid?

    assert p1 = Place.create(:name => @name, :street => @street, :number => @number, :url => @url, :city => @city)
    assert !p1.valid?

    assert p2 = Place.create(:name => @name, :street => @street, :number => "22/b", :url => @url, :city => @city)
    assert p2.valid?
  end

#  def test_proxying
#    assert p = Place.create(:name => "test_creation")
#    assert c = p.classrooms.create(:name => "test_classrooms")
#    assert !p.classrooms.blank?
#
#  end

end
