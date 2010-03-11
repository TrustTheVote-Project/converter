#
# Perform some unit tests on Generator, ParserCSV
#
require 'rubygems'
require 'shoulda'
require 'flparser'
require 'data_layer'

class ParserCSVTest < Test::Unit::TestCase

  context "A generator instance" do
    setup do
      @gen = DataLayer.new('FL')
    end
    
    should "start and end a precinct" do
        @gen.start_precinct("Baker")
        @gen.end_precinct
    end
      
    should "start precinct, add some districts, end precinct." do
        @gen.start_precinct("Test")
        @gen.add_district("Congress 1")
        @gen.add_district("Senate 2")
        @gen.add_district("House 1")
        @gen.end_precinct
    end
  end
  
  context "A parser_csv on a small csv file" do
    setup do
      @gen = DataLayer.new('FL')
      @par = FLParser.new("inputs/smallpandd.csv", @gen)      
    end
  
    context "skipping blank/header rows, having found precinct rows" do
      setup do
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
      @par.parse_precincts
    end
  end
  
end