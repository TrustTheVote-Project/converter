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

class Generator
  attr_reader :h_file
  
  def initialize(formcode)
    @format = formcode
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
  
  def begin_file
    @h_file = []
    
  end
  
  def end_file
    #    pp @h_file
  end

  def start_precinct(name)
    puts "new precinct: #{name}"
    @prec_count += 1
    @precinct = {"display_name" => name}
    @districts = [] # Empty districts
  end
  
  def end_precinct
    @precinct["districts"] = @districts
    @h_precincts << @precinct
  end
  
  def add_district(district)
    @districts << {"display name" => district}
  end
  
  def start_ballot(town)
    puts "new ballot: #{town}"
    @ballot_count += 1
    @prec_id = "prec-#{@precincts.length}"
    @precincts = {town => @prec_id}
    # if @format = "TXT" ?
    @h_ballot = {"display_name" => "General Election"}
    @h_ballot["contest_list"] = []

  end
  
  def end_ballot
    
    if @format == "TXT"
      gen_precinct_list
      @h_ballot["jurisdiction_display_name"] = "middleworld"
      @h_ballot["type"] = "jurisdiction_slate"
    
    elsif @format == "CSV"
      @h_ballot["ballotinfo_type"] = "jurisdiction_info"
    end

    @h_ballot["precinct_list"] = @h_precincts
    
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
