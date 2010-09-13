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
class DataLayer2
  attr_reader :h_file, :audit_header_hash
  
  def initialize file_type
    @ftype = file_type
    @audit_header_hash = {
        "file_id" => "9F023408009B11DF924800163E3DE33F",
        "create_date" => DateTime.now,
        "type" => "jurisdiction_slate",
        "operator" => "Pito Salas",
        "hardware" => "n/a",
        "software" => "TTV Election Management System 0.1 JAN-1-2010",
        "schema_version" => "0.2"
    }  
  end
  
  # Initialize an output array to later store ballots in
  def begin_file
    @out_file = {}
    case @ftype
    when :jurisdiction
      @out_file["districts"] = []
      @out_file["precincts"] = []
      @out_file["splits"] = []
      @out_file["district_sets"] = []
      @audit_header_hash["type"] = "jurisdiction"
    when :election
      @out_file["elections"] = []
      @out_file["contests"] = []
      @audit_header_hash["type"] = "elections" 
    when :candidate
      @out_file["candidates"] = []
      @audit_header_hash["type"] = "candidates"
    else
      raise ArgumentError, "DataLater2 called with invalid file type: #{@ftype}"
    end
  end
  
# h_file at top level is an array, each corresponding to one eventual output file.
  def end_file
    @h_file = {"audit_header" => @audit_header_hash, "body" => @out_file}
  end

  def add_precinct(prec_ident, prec_name)
    @curr_precinct = {"ident" => prec_ident, "display_name" => prec_name}
    @out_file["precincts"] <<  @curr_precinct
  end
  
  def add_precinct_split(prec_split_ident, prec_split_name, parent_prec_ident, district_set_name)
    @curr_precinct_split = {"precinct_ident" => parent_prec_ident, 
                            "ident" => prec_split_ident,
                            "display_name" => prec_split_name,
                            "district_set_ident" => district_set_name}
    @out_file["splits"] << @curr_precinct_split
  end
  
  def add_district_set(ident, dists)
    @curr_district_set = {"ident" => ident, "district_list" => []}
    dists.each {|d| @curr_district_set["district_list"] << {"district_ident" => d} }
    @out_file["district_sets"] << @curr_district_set
  end 
    
  def add_district(ident, name, type, abbrev)
    @curr_district = {"ident" => ident, "display_name" => name, "type" => abbrev}
    @out_file["districts"] << @curr_district
  end
  
  def add_election(type, edate, etype)
    @curr_election = {"ident" => type, "start_date" => edate, "type" => etype}
    @out_file["elections"] << @curr_election
  end
  
  def add_contest (id, election_ident, district_ident, office_display_name, placement)
    @curr_contest = {"ident" => id, "display_name" => office_display_name,  "election_ident" => election_ident, "district_ident" => district_ident}
    @out_file["contests"] << @curr_contest
  end
  
  def add_candidate(ident, contest_ident, candidate_display_name, candidate_party)
    @curr_candidate = {"ident" => ident, 
                       "contest_ident" => contest_ident, 
                       "display_name" => candidate_display_name, 
                       "party_display_name" => candidate_party}
    @out_file["candidates"] << @curr_candidate
  end

end
