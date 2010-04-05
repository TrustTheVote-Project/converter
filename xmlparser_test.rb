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
    
    should "parse precincts, incl. display ordering" do
      @par.parse_precincts
      @gen.end_ballot
      @gen.end_file
      
      # Splits should have their display order set
      assert_equal 26, @gen.h_file[0]["precinct_list"][0]["display_order"]
    end
    
    context "after parsing contests" do
      setup do
        @par.parse_district_names
        @par.parse_contest_district
        
        @par.parse_precincts
        @par.parse_contests
        
        @gen.end_ballot
        @gen.end_file
      end
      
      should "store display order" do   
        assert_equal 406, @gen.h_file[0]["contest_list"][0]["display_order"]
      end
      
      should "store contests' districts" do

        assert_equal @gen.district_ident("City of Shelton"), @gen.h_file[0]["contest_list"][0]["district_ident"]
        assert_equal "City of Shelton Commissioner of Streets and Public Improvement", @gen.h_file[0]["contest_list"][0]["display_name"]

        #assert_equal "Mason County", @gen.omgtest
      end

      should "store a question and its districts" do
        assert_equal "State Initiative Measure 1033", @gen.h_file[0]["question_list"][0]["display_name"]
        assert_equal  "Initiative Measure No. 1033 concerns state, county and city revenue. | |This measure would limit growth of certain state, county and city revenue to annual inflation and population growth, not including voter-approved revenue increases. Revenue collected above the limit would reduce property tax levies.  | |Should this measure be enacted into law? Yes [ ] No [ ]",
                      @gen.h_file[0]["question_list"][0]["question"]
        assert_equal  @gen.district_ident("Mason County"),
                      @gen.h_file[0]["question_list"][0]["district_ident"]
      end
    
    end
    
  end
  
end