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
      @gen.start_ballot("Test Election")    
    end
    
    should "begin a contest with two candidates" do
      @gen.start_contest("Test Contest") # No rules specified
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
  
  # begin_file start_ballot [display_name]<County><Election> (name)
    # [contest_list]<Contests>
      # start_contest [candidates] <Contest>
        # <MeasureText> (opt)
  # add_candidate [display name] <Choice>
  # <DistrictContests>
  # [precinct_list] <Precincts>
  # start_precinct [display_name] <Precinct> (name) #
  # <Splits>
  # <Split> (name) #
  # [district_list]<DistrictPrecinctSplits>
  # add_district [district]<DistrictPrecinctSplit> (district) # (lookup name)
  # <Districts>
  # <District> (name, type)
  # assign_district(contest, district) <DistrictContest> (contest --> district) 
  
  context "A XMLParser instance" do
    setup do
      @gen = Generator.new("XML")
      @par = XMLParser.new("inputs/mason.edx")
      @doc = @par.doc
    end
    
    should "find election name from XML file" do
      name = @doc.elements["EDX/County/Election"].attributes["name"]
      assert_equals name, "general"
    end
    
    should "find contest and its candidates" do
      contest = @doc.elements["EDX/County/Election/Contests/Contest"]
      contestname = @doc.elements["EDX/County/Election/Contests/Contest"].attributes["name"]
      contestrule = "Vote for " + doc.elements["EDX/County/Election/Contests/Contest"].attributes["maxVotes"]
      
      assert_equals contestname, "State Initiative Measure 1033"
      assert_equals contestrule, "Vote for 1"
      
      # start_contest(contestname, contestrule)
    end
    
    

    #require "rexml/document"
    #include REXML
    #doc = Document.new File.new("inputs/mason.edx")
    #doc.elements.each("EDX/County/Election/DistrictContests/DistrictContest") {|element| puts element.attributes["contest"] + " " + element.attributes["district"]}

    
    
  end
  
end