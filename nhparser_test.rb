#
# Perform some unit tests on Parser
#
require 'rubygems'
require 'shoulda'
require 'nhparser'
require 'data_layer'

class ParserTest < Test::Unit::TestCase
  context "A single parser instance" do
    should "open a ballot info text file" do
      gen = DataLayer.new
      par = NHParser.new("inputs/tinyballot.txt", gen)      
    end
    
    should "parse a ballot info text file" do
      gen = DataLayer.new
      par = NHParser.new("inputs/tinyballot.txt", gen)
      par.parse_file
      assert true unless gen.h_file.nil? # generated file
      assert_equal 1, gen.h_file.length # 1 ballot
      
      single_ballot = gen.h_file[0]

      assert_equal "jurisdiction_slate", single_ballot["Audit-header"]["type"]
      assert_equal 2, single_ballot["contest_list"].length
      assert_equal  "President and Vice-President of the United States",
                    single_ballot["contest_list"][0]["display_name"]
    end
  end
end