#
# $Id: string_extensions_test.rb 176 2009-11-17 05:28:54Z nicb $
#
require 'test/test_helper'

require 'string'

class StringExtensionsTest < ActiveSupport::TestCase

  def test_create_acronym
    #
    assert s = 'questo è un test di acronimi'
    assert_equal 'QA', s.create_acronym
    #
    assert s = 'questo è un altro test di acronimi'
    assert_equal 'QAA', s.create_acronym
    #
    assert s = "ed infine questo è un ennesimo test dell'acronimo più fico"
    assert_equal 'IQEA', s.create_acronym
    #
    assert s = "Tecniche dell'Organizzazione Musicale"
    assert_equal 'TOM', s.create_acronym
    #
    assert s = "Teoria generale della Musica"
    assert_equal 'TGM', s.create_acronym
    #
    assert s = "Teoria generale degli Sbrisigotti"
    assert_equal 'TGS', s.create_acronym
    #
    #
    assert s = "Teoria di questo e di quello 3 (con parentesi)"
    assert_equal 'TQQ', s.create_acronym
  end

  def test_limits
    #
    assert s = 'Questo è un Acronimo che Volendo ha Molto di Più di Settesette Parti Tantoevvero che ne ha NoveNove'
    assert_equal 'QAVMSPT', s.create_acronym
    #
    assert s = 'Acronimo'
    assert_equal 'ACRO', s.create_acronym
    #
    assert s = 'Acronimo di Base'
    assert_equal 'ACRO', s.create_acronym
  end

  def test_specials
    #
    String::UNCONVENTIONAL_ACRONYMS.each do
      |k, v|
      assert s = k
      assert_equal v, s.create_acronym
    end
  end

  def test_capitalize_all
    #
    assert s = 'La manfrina degli uguali non capitalizzati'
    assert_equal 'La Manfrina degli Uguali non Capitalizzati', s.capitalize_all
    #
    assert s = 'Ergonomia'
    assert_equal 'Ergonomia', s.capitalize_all
  end

end
