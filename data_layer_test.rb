#
# Perform some unit tests on Data Layer
#
require 'rubygems'
require 'shoulda'
require 'xmlparser'
require 'data_layer'

class DataLayerTest < Test::Unit::TestCase
  context "A data_layer instance" do
    setup do
      @gen = DataLayer.new
      @gen.begin_file
      @gen.start_ballot "display_name"
    end
    
    should "have set the ballot display_name" do
      @gen.end_ballot
      @gen.end_file
      assert_equal "display_name", @gen.h_file[0]["display_name"]
    end
    
    should "create multiple ballots" do
      @gen.end_ballot
      @gen.start_ballot "Ballot 2"
      @gen.end_ballot
      @gen.start_ballot "Ballot 3"
      @gen.end_ballot
      
      @gen.end_file
      
      assert_equal 3, @gen.h_file.length
      assert_equal "Ballot 2", @gen.h_file[1]["display_name"]
    end
    
    should "begin a contest with two candidates" do
      @gen.start_contest "Test Contest"  # No rules specified
      @gen.add_candidate "Candidate 1", "Party 1"
      @gen.add_candidate "Candidate 2" # No party specified
      @gen.end_contest

      @gen.end_ballot
      @gen.end_file
      
      contest_file = @gen.h_file[0]["contest_list"][0]
      assert_equal contest_file["display_name"], "Test Contest"
      assert_equal contest_file["candidates"][0]["display_name"], "Candidate 1"

      assert_equal contest_file["candidates"][0]["ident"], "CAND-0"
      assert_equal contest_file["candidates"][1]["party_ident"], "PART-0" # No party
      assert_equal contest_file["candidates"][0]["party_display_name"], "Party 1"
    end

    should "associate a contest with a district" do      
      @gen.start_contest "Test Contest"
      @gen.contest_district "Test District"
      @gen.end_contest
      
      @gen.end_ballot
      @gen.end_file
      
      assert_equal @gen.h_file[0]["contest_list"][0]["district_ident"], "DIST-0"
    end
      
    should "set a ballotinfo_type" do
      @gen.set_type "jurisdiction_slate"
      
      @gen.end_ballot
      @gen.end_file
      
      assert_equal "jurisdiction_slate", @gen.h_file[0]["Audit-header"]["type"]
    end
      
    should "store precincts with districts" do
      @gen.start_precinct("Precinct Display Name")
      @gen.add_district("House 1")
      @gen.add_district("Congress 3")
      @gen.add_district("Fire 12")
      @gen.end_precinct

      @gen.start_precinct("Precinct 2 Display Name")
      @gen.add_district("House 1")
      @gen.end_precinct
      
      @gen.end_ballot
      @gen.end_file
      
      precinct_file = @gen.h_file[0]["precinct_list"][0]
      assert_equal "Precinct Display Name", precinct_file["display_name"]
      assert_equal "DIST-0", precinct_file["district_list"][0]["ident"]
      assert_equal "House 1", precinct_file["district_list"][0]["display_name"]
      
      precinct_file_2 = @gen.h_file[0]["precinct_list"][1]

      # Districts with the same name should have the same ident across precincts
      assert_equal  precinct_file["district_list"][0]["ident"],
                    precinct_file_2["district_list"][0]["ident"]
    end

    should "store ordered precincts" do
      @gen.start_precinct("Precinct 1", 3)
      @gen.end_precinct
      @gen.start_precinct("Precinct 2", 1)
      @gen.end_precinct
      
      @gen.end_ballot
      @gen.end_file
      
      assert_equal 3, @gen.h_file[0]["precinct_list"][0]["display_order"]
      assert_equal 1, @gen.h_file[0]["precinct_list"][1]["display_order"]
    end
    
    should "store ordered contests, candidates" do
      @gen.start_contest("Test Contest", 3)
      @gen.add_candidate("Candidate 1", "Unaffiliated", 60)
      @gen.add_candidate("Candidate 2", "Green Party", 59)
      @gen.end_contest
      
      @gen.end_ballot
      @gen.end_file
      
      assert_equal 3, @gen.h_file[0]["contest_list"][0]["display_order"]
      assert_equal 60, @gen.h_file[0]["contest_list"][0]["candidates"][0]["display_order"]
      assert_equal 59, @gen.h_file[0]["contest_list"][0]["candidates"][1]["display_order"]
    end
    
    should "generate unique idents for precincts" do
      assert_equal "PREC-0", @gen.precinct_ident("Test Name")
      assert_equal "PREC-1", @gen.precinct_ident("Different Test Name")
      assert_equal "PREC-0", @gen.precinct_ident("Test Name")
    end
    
    should "generate unique idents for districts" do
      assert_equal "DIST-0", @gen.district_ident("Test Name")
      assert_equal "DIST-1", @gen.district_ident("Different Test Name")
      assert_equal "DIST-0", @gen.district_ident("Test Name")
    end
    
    should "generate unique idents for parties" do
      # PART-0 is "Unaffiliated"
      assert_equal "PART-1", @gen.party_ident("Test Name")
      assert_equal "PART-2", @gen.party_ident("Different Test Name")
      assert_equal "PART-1", @gen.party_ident("Test Name")
      assert_equal "PART-0", @gen.party_ident("Unaffiliated")

    end
    
    should "generate unique idents for candidates" do
      assert_equal "CAND-0", @gen.candidate_ident("Test Name")
      assert_equal "CAND-1", @gen.candidate_ident("Different Test Name")
      assert_equal "CAND-0", @gen.candidate_ident("Test Name")
    end
    
    should "generate unique idents for contests" do
      assert_equal "CONT-0", @gen.contest_ident("Test Name")
      assert_equal "CONT-1", @gen.contest_ident("Different Test Name")
      assert_equal "CONT-0", @gen.contest_ident("Test Name")
    end
    
  end
end