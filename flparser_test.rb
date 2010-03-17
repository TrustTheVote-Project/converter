#
# Perform some unit tests on Generator, ParserCSV
#
require 'rubygems'
require 'shoulda'
require 'flparser'
require 'data_layer'

class ParserCSVTest < Test::Unit::TestCase
  
  context "A parser_csv on a small csv file" do
    setup do
      @gen = DataLayer.new
      @par = FLParser.new("inputs/smallpandd.csv", @gen)
    end
  
    context "skipping blank/header rows, having found precinct rows" do
      setup do
        @gen.begin_file
        @gen.start_ballot
        
        until @par.is_precinct?
          @par.get_row
        end
      end
      
      should "verify row is a precinct row" do
        assert @par.is_precinct?
      end
      
      should "send fields from row into generator" do
        @par.parse_precinct
      end
    end
    
    context "having parsed all precincts" do
      setup do
        @par.parse_file
      end
      
      should "set audit header ballot type" do
        assert_equal "jurisdiction_info", @gen.h_file[0]["Audit-header"]["type"]
      end
      
      should "extract precincts and send to generator" do
        assert_equal "Baker 01.1", @gen.h_file[0]["precinct_list"][0]["display_name"]
        assert_equal "Blackman 02.1", @gen.h_file[0]["precinct_list"][1]["display_name"]
      end
      
      should "associate precincts with its districts" do
        assert_equal "Congress 1", @gen.h_file[0]["precinct_list"][0]["district_list"][0]["display_name"]
        assert_equal "Senate 2", @gen.h_file[0]["precinct_list"][0]["district_list"][1]["display_name"]
      end

    end
  end
  
end