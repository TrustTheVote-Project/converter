#!/usr/bin/env ruby
=begin
  * Name: conv
  * Description: TTV File Converter
  * Author: Pito Salas
  * Copyright: (c) R. Pito Salas and Associates, Inc.
  * Date: January 2010
  * License: GPL

  This is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Ballot-Analyzer.  If not, see <http://www.gnu.org/licenses/>.

=end
require 'rubygems'
require 'yaml'
require 'pp'
require 'getoptlong'
require 'pathname'
require 'shoulda'

#
# Implements a simple top-down parser for the New Hampshire formatted input file.  @line is the current line, and @lookahead is the next line.
# Some of the syntax requires us to know what the next line looks like. At interesting points in the parsing, we call Generator who then 
# uses what the parser knows to build up what is to be written out.
class Parser
  
  def initialize(fname, generator)
    @file = File.open(fname)
    @lookahead = ""
    @line = ""
    @gen = generator
  end
  
  def get_line
    @line = @lookahead
    if !@file.eof?
      @lookahead = @file.readline.chomp
    else
      @lookahead = ""
    end
  end
  
  #
  # Parse the whole file. A file consists of a series of ballots. The two get_lines prime the two key
  # parser variables, @line and @lookahead.
  #
  def parse_file()
    @gen.begin_file
    get_line
    get_line
    if @lookahead != ""
      parse_ballots()
    end
    @gen.end_file
  end
  
  #
  # Parse a series of ballots. The last ballot occurs when we see the end-of-file.
  # 
  def parse_ballots
    while !@file.eof?
      parse_ballot
    end
  end
  
  #
  # Parse a single ballot. Always start with the string "General Election Ballot". The first line after that is 
  # the town name. Skip a line and then we expect a series of contests.
  #
  def parse_ballot
    raise "unexpected start of section" unless @line == "General Election Ballot"
    get_line
    town = @line
    puts "parsed town: #{town}"
    get_line
    get_line
    @gen.start_ballot(town)
    parse_contests
    @gen.end_ballot
  end
  
  #
  # Contests are one after the other, until we hit the start of the next ballot.
  #
  def parse_contests
    while @line != "General Election Ballot" && !@file.eof?
      @contest = @line.chomp
      get_line
      @rule = @line.chop.lstrip
      get_line
      @gen.start_contest(@contest, @rule)
      parse_candidates()
      @gen.end_contest
    end
  end
  
  #
  # Parse one or more candidates for this contest. Next contest starts when non-indented line is seen.
  #
  def parse_candidates()
    while line_indented?
      parse_candidate
    end
  end
  
  def line_indented?
    @line[0] == 32
  end
  
  def parse_candidate
    name = @line.chomp.lstrip
    get_line
    party = @line.chomp.lstrip
    get_line
    @gen.add_candidate(name, party)
  end
end

class Generator
  attr_reader :h_file
  
  def initialize
    @rules = {}
    @candidates = {}
    @parties = {}
    @precincts = {}
    @cont_count = 0
    @prec_count = 0
    @ballot_count = 0
  end
  
  def begin_file
    @h_file = []
    
  end
  
  def end_file
    #    pp @h_file
  end
  
  def start_ballot(town)
    puts "new ballot: #{town}"
    @ballot_count += 1
    @prec_id = "prec-#{@precincts.length}"
    @precincts = {town => @prec_id}
    @h_ballot = {"display_name" => "General Election"}
    @h_ballot["contest_list"] = []
  end
  
  def end_ballot
    gen_precinct_list
    @h_ballot["precinct_list"] = @h_precincts
    @h_ballot["jurisdiction_display_name"] = "middleworld"
    @h_ballot["type"] = "jurisdiction_slate"
    @h_file << @h_ballot
  end
  
  def gen_precinct_list
    @h_precincts = []
    @precincts.each do |key, value|
      @h_precincts << 
      { "voting_places" =>
        [{ "ballot_counters" => 2,
              "ident" => "vplace-xxx"}
        ],
          "display_name" => key,
          "ident" => value,
          "district_list" =>
        [{ "ident" => value,
               "display_name" => key}
        ]
      }
    end
  end
  
  def start_contest(name, rule)
    @h_contest = {"display_name" => name}
    @h_contest["district_ident"] = @prec_id
    @h_contest["ident"] = "cont-xx"
    @h_contest["candidates"] = []
    add_rule(rule)
  end
  
  def end_contest
    @h_ballot["contest_list"] << @h_contest
  end
  
  def add_rule(rule)
    @rules[rule] = 1
  end
  
  def add_candidate(name, party)
    @parties[party] = "party-#{@parties.length}"
    @candidates[name] = "cand-#{@candidates.length}"
    
    @h_contest["candidates"] << 
    {"party_ident" => @parties[party], 
       "ident" => @candidates[name],
       "display_name" => name}
    @parties[party] = party
    @candidates[name] = party
  end
end

#
# Perform some unit tests on Generator and Parser
#
class GeneratorTests < Test::Unit::TestCase

  context "A single generator instance" do
    should "begin a file" do
      gen = Generator.new
      gen.begin_file
      assert true unless gen.h_file.nil?
    end
    
    context "with a single ballot" do
      should "start and end ballot and contest with one candidate" do
        gen = Generator.new
        gen.begin_file
        gen.start_ballot("Town name A")
        gen.start_contest("Contest name", "Contest Rules")
        gen.add_candidate("Person 3 and Person 4", "Cheese Party")
        gen.end_contest
        gen.end_ballot
        assert true unless gen.h_file.empty?
      end
      
      should "start and end ballot and contest with two candidates" do
        gen = Generator.new
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
        gen = Generator.new
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
        gen = Generator.new
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

  #
  # This test func is too broad, doesn't use shoulda style
  #
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

#
# Main Program: Parse the command line and do the work
#
HELPTEXT = "TTV File Coverter.
Converts text file with ballot info into TTV standard data layer
Usage:
    conv [-options] file

 Options:
     -h   display help text
     -f   format code. -fNH - New Hampshire Ballot.txt
     -o   optional destination folder
"
opts = GetoptLong.new(
      ["-h", "--help", GetoptLong::NO_ARGUMENT],
      ["-f", "--format", GetoptLong::REQUIRED_ARGUMENT],
      ["-o", "--output", GetoptLong::REQUIRED_ARGUMENT])
@format = nil
@dir = Pathname.new(".")
opts.each do |opt, arg|
  case opt
    when "-h"
      puts HELPTEXT
      exit 0
    when "-f"
      @format = arg
      break
    when "-o"
      @dir = Pathname.new(arg)
      if @dir.exist? && !@dir.directory?
        puts "#{arg} doesn't seem to be a directory" unless @dir.directory?
        exit 0
    end
  end
end

if ARGV.length != 1
  puts "Missing file argument (try --help)"
  exit 0
end

# command line is parsed. Now lets do the work

gen = Generator.new
par = Parser.new(ARGV[0], gen)
par.parse_file

@dir.mkdir unless @dir.directory?
@dir = @dir.realpath
i = 0
gen.h_file.each do |ballot|
  i += 1
  puts "ballot #{i}: #{ballot["precinct_list"][0]["display_name"]}"
end
gen.h_file.each do |ballot|
  @file = @dir + "#{ballot["precinct_list"][0]["display_name"]}.yml"
  puts "writing file #{@file}"
  @file.open("w") do |file| 
    YAML.dump(ballot, file)
  end
end
