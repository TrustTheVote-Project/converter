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
        # will need last precinct name stored as local var
      end

        # generate YAML with generator, end file
        # check for proper resulting file, based on known input      
    end
    
    should "parse all precincts" do
      @par.parse_file
      
      assert_equal "Baker 01.1", @gen.h_file[0]["precinct_list"][0]["display_name"]
      assert_equal "Congress 1", @gen.h_file[0]["precinct_list"][0]["district_list"][0]["display_name"]

    end
  end
  
end