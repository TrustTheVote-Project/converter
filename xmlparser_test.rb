#
# Perform some unit tests on Parser
#
require 'rubygems'
require 'shoulda'
require 'xmlparser'
require 'data_layer'

class XMLParserTest < Test::Unit::TestCase
  context "A generator instance" do
    setup do
      @gen = DataLayer.new
      @gen.begin_file
      @gen.start_ballot    
    end
    
    should "begin a contest with two candidates" do
      @gen.start_contest("Test Contest", "Vote for only one") # No rules specified
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
  
  context "XMLParser testing" do
    setup do
      @gen = DataLayer.new
      @gen.begin_file
      @gen.start_ballot
      
      @par = XMLParser.new("inputs/mason.xml", @gen)
      @doc = @par.file
    end

    context "having parsed a file" do
      setup do
        @par.parse_file
      end
      
      should "have imported a precinct" do
        # TODO: check for ordering data
        # of precincts, contests, candidates
      end
      
    end
    
    should "find election name from XML file" do
      name = @doc.elements["EDX/County/Election"].attributes["name"]
      assert_equal name, "General"
      
      @par.start_election
    end
    
    should "find a contest and a candidate" do
      contest = @doc.elements["EDX/County/Election/Contests/Contest"]
      contestname = contest.attributes["name"]
      contestrule = "Vote for " + contest.attributes["maxVotes"]
      
      assert_equal contestname, "State Initiative Measure 1033"
      assert_equal contestrule, "Vote for 1"
      
      @gen.start_contest(contestname, contestrule)
      
      candidate = contest.elements["Choice"].attributes["name"]
      
      @gen.add_candidate(candidate, "Nonpartisan")
      
      assert_equal candidate, "Yes"
    end
    
    should "find all precincts, splits" do
      @doc.elements.each("EDX/County/Election/Precincts/Precinct") { |precinct|

        precinct.elements.each("Splits/Split") {|split|
          #puts precinct.attributes["name"] + "." + split.attributes["name"]
          @gen.start_precinct(precinct.attributes["name"] + "." + split.attributes["name"], precinct.attributes["displayOrder"])
          
          split.elements.each("DistrictPrecinctSplits/DistrictPrecinctSplit") { |district|
            #print district.attributes["district"] + " "
            @gen.add_district(district.attributes["district"])
          }
          #puts
        }
      }
    end
    
    should "look up district names" do
      @par.parse_district_names

      assert_equal @par.district_name(1), "Mason County"
      assert_equal @par.district_name(37), "Hartstene Pointe Water"
    end
    
    should "parse precincts" do
      @par.parse_precincts
    end
    
    should "parse contests" do
      @par.parse_contests
    end
    
  end
  
end