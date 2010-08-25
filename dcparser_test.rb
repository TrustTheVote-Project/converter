#
# Perform some unit tests on Generator, DC Importer
#
require 'rubygems'
require 'shoulda'
require 'dcparser'
require 'data_layer_v2'

class DCParserTest < Test::Unit::TestCase
  
  context "parsing mini_districts" do
    setup do
      @gen = DataLayer2.new
      @par = DCParser.new("inputs/dc/mini_districts_precincts.csv", @gen)
      @gen.begin_file
    end
    
    should "get district number" do
      assert_equal 20, @par.district_number
    end
    
    should "get district name" do
      assert_equal "ANC 6C SMD 1-9", @par.district_name
    end
    
    should "get district type" do
      assert_equal "ADVISORY NEIGHBORHOOD COMM", @par.district_type
    end
    
    should "get district abbrev" do
      assert_equal "ANC", @par.district_type_abbrev
    end
    
    should "get precinct number" do
      assert_equal 1, @par.precinct_number
    end
    
    should "get precint name" do
      assert_equal "PRECINCT 1", @par.precinct_name
    end
    
    should "identify anc" do
      assert @par.dist_anc?
    end
    
    should "identify regular district" do
      @par.get_row
      assert @par.dist_regular?
    end
    
    should "load a district" do
      the_dist = @par.parse_district
      assert_nil the_dist
      @par.get_row
      the_dist = @par.parse_district
      assert_equal "CITY OF WASHINGTON WARD 6",the_dist.name
      assert_equal "WARD", the_dist.abbrev
      assert_equal "CITY WARD", the_dist.type
    end
    
    should "correctly load 1st precinct" do
      @par.get_row
      the_prec = @par.parse_precinct
      @gen.end_file
      assert_equal 7, @gen.h_file[0]["districts"].length
      assert_equal 4, @gen.h_file[0]["splits"].length
      assert_equal 4, @gen.h_file[0]["district_sets"].length   
    end
    
    should "correctly load 2nd precinct" do
      @par.get_row
      the_prec = @par.parse_precinct
      @gen.end_file
      @gen.begin_file
      the_prec = @par.parse_precinct
      @gen.end_file
      ap @gen.h_file
      assert_equal 6, @gen.h_file[0]["districts"].length
      assert_equal 4, @gen.h_file[0]["splits"].length
      assert_equal 4, @gen.h_file[0]["district_sets"].length   
    end
  end

#  PNUMBER = 0
#  PNAME = 1
#  DNUMBER = 2
#  DNAME = 3
# DTYPE = 4
#  DTYPEABBREV = 5

  context "again" do
    setup do
      data = [[1, "Prec 1", 1, "Dist 1", "Test", "TEST"], 
              [1, "Prec 1", 2, "Dist 2", "Test", "TEST"]]
      @gen = DataLayer2.new 
      @par = DCParser.new data, @gen
      @gen.begin_file
    end
    
    should "initialize correctly with fake data" do
      assert_equal "Prec 1", @par.precinct_name
    end
    
# initialize id, nm, typ, abbr

    should "Create a simple split" do
      precinct = "precinct 123"
      dists = [District.new("dist 123-1", "dist 123-1", "XXX", "XXX"), 
               District.new("dist 123-2", "dist 123-2", "XXX", "XXX")]
      @par.compute_precinct_splits precinct, dists
      @gen.end_file
      assert_equal 1, @gen.h_file[0]["district_sets"].length
      assert_equal "ds-precinct 123", @gen.h_file[0]["district_sets"][0]["district_set"]["ident"]
    end
    
    should "create a more difficult split" do
      precinct = "precinct 888"
      dists = [District.new("dist 888-S1", "dist 888-1S1", "XXX", "SMD"),
               District.new("dist 888-1", "dist 888-1", "XXX", "XXX")]
      @par.compute_precinct_splits precinct, dists
      @gen.end_file
      assert_equal 1, @gen.h_file[0]["district_sets"].length
      assert_equal "0-dist 888-S1", @gen.h_file[0]["district_sets"][0]["district_set"]["ident"]
  end
      
  end
end
