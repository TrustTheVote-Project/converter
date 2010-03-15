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
require 'active_support/secure_random'


# Contains methods to build BallotInfo records which fit the TTV data model.  
class DataLayer
  attr_reader :h_file
  
  def initialize()
    @all_district_idents = {}
    @all_precinct_idents = {}
    @all_candidate_idents = {}
    @all_voting_place_idents = {}
    @rules = {}
    @candidates = {}
    @parties = {}
    @precincts = {}
    @districts = {}
    @h_precincts = []
    @cont_count = 0
    @prec_count = 0
    @ballot_count = 0
  end
  
  def audit_header_dummy
    @audit_header_hash = {
        "file_id" => "9F023408009B11DF924800163E3DE33F",
        "create_date" => DateTime.now,
        "type" => "jurisdiction_slate",
        "operator" => "Pito Salas",
        "hardware" => "TTV Tabulator TAB02",
        "software" => "TTV Election Management System 0.1 JAN-1-2010"
    }
    @audit_header_hash
  end
  
  def begin_file
    @h_file = []
  end
  
  def end_file
    #    pp @h_file
  end

  # Begin a precinct record
  def start_precinct(name)
    puts "new precinct: #{name}"
    @prec_count += 1
    @curr_precinct = {"display_name" => name}
    @districts = [] # Empty temporary district list
  end
  
  # End a precinct record. Associate added districts with precinct.
  def end_precinct
    @curr_precinct["districts"] = @districts
    @h_precincts << @curr_precinct
  end
  
  # Add a district to the precinct currently being added
  def add_district(name)
    @districts << {"display name" => name}
    # TODO: Set unique district ident
  end
  
  def start_ballot(name)
    puts "new ballot: #{name}"
    @ballot_count += 1
    @prec_id = "prec-#{@precincts.length}"

    @h_ballot = {"display_name" => name}
    @h_ballot["contest_list"] = []

  end
  
  def end_ballot
    
    @h_ballot["precinct_list"] = @h_precincts
    @h_ballot.merge!(audit_header_dummy)
    
    @h_file << @h_ballot
  end
  
  def gen_precinct_list
    @h_precincts = []
    @precincts.each do |key, value|
      @h_precincts << 
      { "voting_places" =>
        # TODO: what are these three lines for?
        [{ "ballot_counters" => 2,
              "ident" => "vplace-#{ActiveSupport::SecureRandom.hex}"}
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
    @h_contest["ident"] = "cont-#{ActiveSupport::SecureRandom.hex}"
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
    @parties[party] = "party-#{ActiveSupport::SecureRandom.hex}"
    @candidates[name] = "cand-#{ActiveSupport::SecureRandom.hex}"
    
    @h_contest["candidates"] << 
    {"party_ident" => @parties[party], 
       "ident" => @candidates[name],
       "display_name" => name}
    @parties[party] = party
    @candidates[name] = party
  end
end
