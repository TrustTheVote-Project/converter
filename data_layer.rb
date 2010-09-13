#!/usr/bin/env ruby
=begin
  * Name: generator
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


# Contains methods to build BallotInfo records which fit the TTV data model.  
class DataLayer
  attr_reader :h_file
  
  def initialize()
    @audit_header_hash = {
        "file_id" => "9F023408009B11DF924800163E3DE33F",
        "create_date" => DateTime.now,
        "type" => "jurisdiction_slate",
        "operator" => "Pito Salas",
        "hardware" => "TTV Tabulator TAB02",
        "software" => "TTV Election Management System 0.1 JAN-1-2010"
    }
    
    @idents = {}
    @idents["parties"] = ["Unaffiliated"]
    @idents["districts"] = []
    @idents["precincts"] = []
    @idents["candidates"] = []
    @idents["contests"] = []
  end
  
  # Initialize an output array to later store ballots in
  def begin_file
    @h_file = []
  end
  
  def end_file
    #    pp @h_file
  end

  # Begin a new ballot. Takes "name", which is display name of ballot.
  def start_ballot(name = "Election")
    puts "new ballot: #{name}"

    @curr_ballot = {}
    @curr_ballot["ballot_info"] = {}

    @ballot_info = {"display_name" => name}
    @ballot_info["contest_list"] = []
    @ballot_info["precinct_list"] = []
    @ballot_info["question_list"] = []
  end
  
  # Add the header to the ballot and push the ballot to the output file  
  def end_ballot
    add_header
    @curr_ballot["ballot_info"] = @ballot_info
    
    @h_file << @curr_ballot
  end

  # Add the dummy audit header to the ballot.
  def add_header
    @curr_ballot["audit_header"] = @audit_header_hash
  end
  
  # Sets ballot type (in header)
  def set_type(type)
    @audit_header_hash["type"] = type
  end

  # Start a question
  # Often followed by a call to question_text and question_district
  def start_question(name, order = -1)
    @curr_question = {"display_name" => name}
    @curr_question["display_order"] = order unless order == -1
    # TODO: Should questions get idents?
  end
  
  def question_text(text)
    @curr_question["question"] = text
  end

  # Given a district name, associates it with the current question
  def question_district(district)
    @curr_question["district_ident"] = district_ident(district)
  end

  def end_question
    @ballot_info["question_list"] << @curr_question
  end

  # Start a contest.
  # Often followed by calls to add_candidate and/or contest_district
  def start_contest(name, order = -1)
    @curr_contest = {"display_name" => name}
    @curr_contest["display_order"] = order unless order == -1
    @curr_contest["ident"] = contest_ident(name)
    @curr_contest["candidates"] = []
  end
  
  # Add a candidate to the current contest. Party is none by default.
  def add_candidate(name, party = "Unaffiliated", order = -1)
    @curr_candidate = {"party_ident" => party_ident(party),
       "party_display_name" => party,
       "ident" => candidate_ident(name),
       "display_name" => name}
    @curr_candidate["display_order"] = order unless order == -1
    @curr_contest["candidates"] << @curr_candidate
  end
  
  # Given a district name, associates a contest with a district ident
  def contest_district(district)
    @curr_contest["district_ident"] = district_ident(district)
  end
  
  def end_contest
    @ballot_info["contest_list"] << @curr_contest
  end
  
  # Begins a precinct record
  # Often followed by calls to add_district
  def start_precinct(name, order = -1)
    puts "new precinct: #{name}"
    
    @curr_precinct = {"display_name" => name}
    @curr_precinct["display_order"] = order unless order == -1
    @curr_precinct["ident"] = precinct_ident(name)
    @curr_precinct["district_list"] = []
  end

  # Add a district to the current precinct
  def add_district(name)
    @curr_district = {"display_name" => name}
    @curr_district["ident"] = district_ident(name)

    @curr_precinct["district_list"] << @curr_district
  end
  
  # End a precinct record. Add precinct to current ballot's list
  def end_precinct
    raise "Must start a precinct before ending one" if @curr_ballot.nil?
    @ballot_info["precinct_list"] << @curr_precinct
  end
  
  
  def party_ident(name)
    ident("PART", "parties", name)
  end
  
  def district_ident(name)
    ident("DIST", "districts", name)
  end
  
  def precinct_ident(name)
    ident("PREC", "precincts", name)
  end
  
  def candidate_ident(name)
    ident("CAND", "candidates", name)
  end
  
  def contest_ident(name)
    ident("CONT", "contests", name)
  end
  
  # Maintain a list of unique ID numbers for names of things of a type
  def ident(prefix, type, name)
    @idents[type][@idents[type].length] = name unless @idents[type].index(name)
    return prefix + "-" + @idents[type].index(name).to_s
  end
  
end
