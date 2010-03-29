#
# Perform some unit tests on Parser
#
require 'rubygems'
require 'shoulda'
require 'nhparser'
require 'data_layer'

class ParserTest < Test::Unit::TestCase
  context "A parser instance on a single ballot" do
    setup do
      @gen = DataLayer.new
      @par = NHParser.new("inputs/tinyballot.txt", @gen)
      @par.parse_file
      @single_ballot = @gen.h_file[0]
    end
    
    should "have one ballot" do
      assert true unless @gen.h_file.nil? # generated file
      assert_equal 1, @gen.h_file.length # 1 ballot
    end
    
    should "set ballot type" do
      assert_equal "ballot_config", @single_ballot["Audit-header"]["type"]
    end
    
    should "contain two contests, have display names" do
      assert_equal 2, @single_ballot["contest_list"].length
      assert_equal  "President and Vice-President of the United States",
                    @single_ballot["contest_list"][0]["display_name"] 
    end
  end
  
  context "A parser instance on two ballots" do
    setup do
      @gen = DataLayer.new
      @par = NHParser.new("inputs/mediumballot.txt", @gen)
      @par.parse_file
      @ballot1 = @gen.h_file[0]
      @ballot2 = @gen.h_file[1]
    end
    
    should "contain two ballots with contests" do
      assert_equal  "President and Vice-President of the United States",
                    @ballot1["contest_list"][0]["display_name"]
      assert_equal  "Governor",
                    @ballot2["contest_list"][1]["display_name"]                    
    end
    
  end
end