#
# Perform some unit tests on Data Layer
# TODO: k.instance_eval { @secret }
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
      assert @gen.h_file[0]["display_name"].eql? "display_name"
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
    end

    should "associate a contest with a district" do
      @gen.start_contest "Test Contest"
      @gen.contest_district "DIST-0"
      @gen.end_contest
      
      @gen.end_ballot
      @gen.end_file
      
      assert_equal @gen.h_file[0]["contest_list"][0]["district_ident"], "DIST-0"
    end
      
    should "set a ballotinfo_type" do
      @gen.set_type "jurisdiction_slate"
      
      @gen.end_ballot
      @gen.end_file
      
      assert @gen.h_file[0]["Audit-header"]["type"].eql? "jurisdiction_slate"
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
      assert_equal precinct_file["display_name"], "Precinct Display Name"
      assert_equal precinct_file["district_list"][0]["ident"], "DIST-0"
      assert_equal precinct_file["district_list"][0]["display_name"], "House 1"
      
      precinct_file_2 = @gen.h_file[0]["precinct_list"][1]

      # Districts with the same name should have the same ident across precincts
      assert_equal  precinct_file["district_list"][0]["ident"],
                    precinct_file_2["district_list"][0]["ident"]
    end
    
    should "generate unique idents for precincts" do
      assert_equal @gen.precinct_ident("Test Name"), "PREC-0"
      assert_equal @gen.precinct_ident("Different Test Name"), "PREC-1"
      assert_equal @gen.precinct_ident("Test Name"), "PREC-0"
    end
    
    should "generate unique idents for districts" do
      assert_equal @gen.district_ident("Test Name"), "DIST-0"
      assert_equal @gen.district_ident("Different Test Name"), "DIST-1"
      assert_equal @gen.district_ident("Test Name"), "DIST-0"
    end
    
    should "generate unique idents for parties" do
      # PART-0 is write-in candidate
      assert_equal @gen.party_ident("Test Name"), "PART-1"
      assert_equal @gen.party_ident("Different Test Name"), "PART-2"
      assert_equal @gen.party_ident("Test Name"), "PART-1"
      assert_equal @gen.party_ident("Unaffiliated"), "PART-0"

    end
    
    should "generate unique idents for candidates" do
      assert_equal @gen.candidate_ident("Test Name"), "CAND-0"
      assert_equal @gen.candidate_ident("Different Test Name"), "CAND-1"
      assert_equal @gen.candidate_ident("Test Name"), "CAND-0"
    end
    
    should "generate unique idents for contests" do
      assert_equal @gen.contest_ident("Test Name"), "CONT-0"
      assert_equal @gen.contest_ident("Different Test Name"), "CONT-1"
      assert_equal @gen.contest_ident("Test Name"), "CONT-0"
    end
    
  end
end