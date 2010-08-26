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
    @curr_precinct = {"ident" => prec_num, "display_name" => prec_name}
    @out_file["precincts"] << {"precinct" => @curr_precinct }
  end
  
  def add_precinct_split(prec_ident, district_set_ident)
    @curr_precinct_split = {"precinct_ident" => prec_ident, "district_set_ident" => district_set_ident}
    @out_file["splits"] << {"precinct_split" => @curr_precinct_split}
  end
  
  def add_district_set(ident, dists)
    @curr_district_set = {"ident" => ident, "districts" => []}
    dists.each {|d| @curr_district_set["districts"] << d }
    @out_file["district_sets"] << {"district_set" => @curr_district_set}
  end 
    
  def add_district(ident, name, type, abbrev)
    @curr_district = {"ident" => ident, "display_name" => name, "type" => abbrev}
#    @out_file["districts"] << {"district" => @curr_district }
    @out_file["districts"] << @curr_district

  end
  
  # Maintain a list of unique ID numbers for names of things of a type
  def ident(prefix, type, name)
    @idents[type][@idents[type].length] = name unless @idents[type].index(name)
    return prefix + "-" + @idents[type].index(name).to_s
  end
  
end
