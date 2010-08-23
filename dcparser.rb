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
require 'ap'
require 'fastercsv'

# Column indexes from the input file

PNUMBER = 0
PNAME = 1
DNUMBER = 2
DNAME = 3
DTYPE = 4
DTYPEABBREV = 5
#
# Implements a parser for the districts_precincts excel file from DC
#
class DCParser
  def initialize(fname, generator)
    @gen = generator
    @csv = FasterCSV.read(fname)
    @row = 0
    get_row  # skip the column headers
  end

# In this input file, each row is a district.
  def parse_file
    @gen.begin_file   
    parse_precincts
    @gen.end_file
  end

# Parse precincts (which are a series of CSV rows with the same precinct number)
  def parse_precincts
    while @row < @csv.length
      parse_precinct
    end
  end

#
# A precinct is represented as a set of districts with the same precinct number
#
  def parse_precinct
    last_precinct = precinct_number
    puts "new precinct: #{last_precinct}"
    new_district_set = []
    begin
      parse_district
      puts "contains district: #{@dist_ident}"
      new_district_set << @dist_ident
      get_row 
    end while @row < @csv.length && last_precinct == precinct_number
    @gen.add_district_set("ds-#{last_precinct}", new_district_set)
    @gen.add_precinct(last_precinct, @csv[last_precinct][PNAME])
  end
        
# Here's the meat: parse a district line
  def parse_district
    if district_type.upcase == "SMD" 
      @dist_ident = district_number + district_name
    elsif district_type_abbrev.upcase != "ANC"
      @dist_ident = district_number
    else # ANC district rows
      return
    end
    @gen.add_district(@dist_ident, district_name, district_type, district_type_abbrev)
  end

  def get_row
    @row = @row + 1 # row data is @csv[row]
  end
  
  def district_number
    @csv[@row][DNUMBER].to_i
  end
  
  def district_name
    @csv[@row][DNAME]
  end
  
  def district_type
    @csv[@row][DTYPE]
  end
  
  def district_type_abbrev
    @csv[@row][DTYPEABBREV]
  end

  def precinct_number
    @csv[@row][PNUMBER].to_i
  end
  
  def precinct_name
    @csv[@row][PNAME]
  end
end
