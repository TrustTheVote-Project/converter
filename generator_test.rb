
#
# Perform some unit tests on Generator
#

require 'rubygems'
require 'shoulda'
require 'data_layer'

class GeneratorTest < Test::Unit::TestCase

  context "A single generator instance" do
    should "begin a file" do
      gen = DataLayer.new('NH')
      gen.begin_file
      assert true unless gen.h_file.nil?
    end
    
    context "with a single ballot" do
      should "start and end ballot and contest with one candidate" do
        gen = DataLayer.new('NH')
        gen.begin_file
        gen.start_ballot("Town name A")
        gen.start_contest("Contest name", "Contest Rules")
        gen.add_candidate("Person 3 and Person 4", "Cheese Party")
        gen.end_contest
        gen.end_ballot
        assert true unless gen.h_file.empty?
      end
      
      should "start and end ballot and contest with two candidates" do
        gen = DataLayer.new('NH')
        gen.begin_file
        gen.start_ballot("Town name B")
        gen.start_contest("Contest name", "Contest Rules")
        gen.add_candidate("Person 1 and Person 2", "Party 1")
        gen.add_candidate("Person 3 and Person 4", "Party 2")
        gen.end_contest
        gen.end_ballot
        assert true unless gen.h_file.empty?
      end
      
      should "start and end two contests with two candidates" do
        gen = DataLayer.new('NH')
        gen.begin_file
        gen.start_ballot("Town name C")
        gen.start_contest("Contest 1", "Contest 1 rules")
        gen.add_candidate("Person 1 and Person 2", "Party 1")
        gen.add_candidate("Person 3 and Person 4", "Party 2")
        gen.end_contest
        gen.start_contest("Contest 2", "Contest 2 rules")
        gen.add_candidate("Person 5 and Person 6", "Party 1")
        gen.add_candidate("Person 7 and Person 8", "Party 2")
        gen.end_ballot
        assert true unless gen.h_file.empty?
      end      
    end
    
    context "with multiple ballots" do
      should "start and end two ballots" do
        gen = DataLayer.new('NH')
        gen.begin_file
        # Ballot 1
        gen.start_ballot("Town name D")
        gen.start_contest("Contest 1", "Contest 1 rules")
        gen.add_candidate("Person 1 and Person 2", "Party 1")
        gen.end_contest
        gen.end_ballot
        # Ballot 2
        gen.start_ballot("Town name E")
        gen.start_contest("Contest 1", "Contest 1 rules")
        gen.add_candidate("Person 1 and Person 2", "Party 1")
        gen.end_contest
        gen.end_ballot
        assert true unless gen.h_file.empty?
      end    
    end
  end
end
