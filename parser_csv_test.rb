#
# Perform some unit tests on Generator, ParserCSV
#
require 'rubygems'
require 'shoulda'
require 'parser_csv'
require './generator'

class ParserCSVTest < Test::Unit::TestCase
  should "Start a generator instance" do
    @gen = Generator.new('CSV')
  end
  
  context "A generator instance" do
    setup do
      @gen = Generator.new('CSV')
    end
    
    context "with a precinct" do
      setup do
        @gen.start_precinct("Baker")
      end
      
      should "Add some districts, end precinct." do
        @gen.add_district("Congress 1")
        @gen.add_district("Senate 2")
        @gen.add_district("House 1")
        @gen.end_precinct
      end
    end
  end
  
  context "A parser_csv on a small csv file" do
    setup do
      @gen = Generator.new
      @par = ParserCSV.new("inputs/tinypandd.csv", gen)      
    end
  
    context "skipping blank/header rows, having found precinct rows" do
      setup do
        until par.is_precinct?
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
    
  end
  
end