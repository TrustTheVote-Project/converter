require "csv"
require "date"
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
require 'fastercsv'

#
# Implements a simple CSV parser for Florida P and D Split list jurisdiction_info
# files
#
class FLParser
  def initialize(fname, generator)
    @gen = generator
    @csv = FasterCSV.read(fname)
    @lastprecinct = ""
    @row = 0
  end

  def parse_file
    @gen.begin_file
    @gen.start_ballot
    @gen.set_type("jurisdiction_info")
    parse_precincts
    @gen.end_ballot
    @gen.end_file
  end

  def parse_precincts
    while @row < @csv.length
      parse_precinct if is_precinct?
      get_row
    end
  end
  
  def get_row
    @row = @row + 1 # row data is @csv[row]
  end
  
  def is_precinct?
    return true unless @csv[@row][1] == "PCT" or @csv[@row][1].nil?
  end
  
  def parse_precinct
    if @csv[@row][2].nil?
      @csv[@row][2] = @lastprecinct
    end
    @lastprecinct = @csv[@row][2] # save last precinct name
    
    @gen.start_precinct(@csv[@row][2] + " " + @csv[@row][1])
    
    @gen.add_district("Congress " + @csv[@row][3]) unless @csv[@row][3].nil?
    @gen.add_district("Senate " + @csv[@row][4]) unless @csv[@row][4].nil?
    @gen.add_district("House " + @csv[@row][5]) unless @csv[@row][5].nil? 
    @gen.add_district("County " + @csv[@row][6]) unless @csv[@row][6].nil?
    @gen.add_district("School board " + @csv[@row][7]) unless @csv[@row][7].nil?
    @gen.add_district("Fire " + @csv[@row][8]) unless @csv[@row][8].nil?
    @gen.add_district("Special " + @csv[@row][40]) unless @csv[@row][40].nil?
    
    @gen.end_precinct
  end
end
