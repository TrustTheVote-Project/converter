#
# Perform some unit tests on Parser
#
require 'rubygems'
require 'shoulda'
require 'parser'
require './generator'

class ParserTest < Test::Unit::TestCase
  context "A single parser instance" do
    should "open a ballot info text file" do
      gen = Generator.new
      par = Parser.new("inputs/tinyballot.txt", gen)      
    end
    
    should "parse a ballot info text file" do
      gen = Generator.new
      par = Parser.new("inputs/tinyballot.txt", gen)
      par.parse_file
      assert true unless gen.h_file.nil? # generated file
      assert gen.h_file.length == 1 # 1 ballot
      single_ballot = gen.h_file[0]
      assert single_ballot["type"].eql? "jurisdiction_slate"
      assert single_ballot["precinct_list"].length == 1
      assert single_ballot["precinct_list"][0]["display_name"] == "Alton"
    end
  end
end