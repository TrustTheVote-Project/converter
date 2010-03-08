#
# Perform some unit tests on Parser
#
require 'rubygems'
require 'shoulda'
require 'xmlparser'
require './generator'

class XMLParserTest < Test::Unit::TestCase
  context "A generator instance" do
    setup do
      @gen = Generator.new("XML")
      @gen.begin_file
      @gen.start_ballot      
    end
    
    should "begin a contest with two candidates" do
      @gen.start_contest("Test Contest", "Vote for only one")
      @gen.add_candidate("Candidate 1", "Party 1")
      @gen.add_candidate("Candidate 2", "Party 2")
      @gen.end_contest

      @gen.end_ballot
      @gen.end_file
    end
      
    should "store a precinct with three districts" do
      @gen.start_precinct("Precinct Display Name")
      @gen.add_district("House 1")
      @gen.add_district("Congress 3")
      @gen.add_district("Fire 12")
      @gen.end_precinct
      
      @gen.end_ballot
      @gen.end_file
    end
    
  end
end