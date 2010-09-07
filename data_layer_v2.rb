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
  attr_reader :h_file
  
  def initialize()
    @audit_header_hash = {
        "file_id" => "9F023408009B11DF924800163E3DE33F",
        "create_date" => DateTime.now,
        "type" => "jurisdiction_slate",
        "operator" => "Pito Salas",
        "hardware" => "TTV Tabulator TAB02",
        "software" => "TTV Election Management System 0.1 JAN-1-2010",
        "schema_version" => "0.1"
    }  
  end
  
  # Initialize an output array to later store ballots in
  def begin_file
    @out_file = {"districts" => [], "precincts" => [], "district_sets" => [], "splits" => []}
  end
  
# h_file at top level is an array, each corresponding to one eventual output file.
  def end_file
    @h_file = {"audit_header" => @audit_header_hash, "body" => @out_file}
  end

  def add_precinct(prec_num, prec_name)
    @curr_precinct = {"ident" => prec_ident(prec_num), "display_name" => prec_name}
    @out_file["precincts"] <<  @curr_precinct
  end
  
  def add_precinct_split(parent_prec, district_set_name)
    @curr_precinct_split = {"precinct_ident" => prec_ident(parent_prec), 
                            "district_set_ident" => district_set_ident(district_set_name)}
    @out_file["splits"] << @curr_precinct_split
  end
  
  def add_district_set(name, dists)
    @curr_district_set = {"ident" => district_set_ident(name), "district_list" => []}
    dists.each {|d| @curr_district_set["district_list"] << {"district_ident" => d} }
    @out_file["district_sets"] << @curr_district_set
  end 
    
  def add_district(ident, name, type, abbrev)
    @curr_district = {"ident" => ident, "display_name" => name, "type" => abbrev}
    @out_file["districts"] << @curr_district
  end
  
  def prec_ident(prec)
    "prec-#{prec}"
  end
  
  def district_set_ident(dist_set)
    "ds-#{dist_set}"
  end

end
