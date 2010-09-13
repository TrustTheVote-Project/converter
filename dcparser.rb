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
    if fname.class == String
      @csv = FasterCSV.read(fname)
      @row = 0
      get_row  # skip the column headers
    elsif fname.class == Array
      @csv = fname
      @row = 0
    end
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
    last_precinct_name = precinct_name
    all_districts_for_this_precinct = []
    begin
      parse_district
      all_districts_for_this_precinct << @new_district unless @new_district.nil?
      get_row 
    end while @row < @csv.length && last_precinct == precinct_number
    compute_precinct_splits last_precinct, all_districts_for_this_precinct
    @gen.add_precinct(last_precinct, last_precinct_name)
  end
  
# this method is the only tricky part, that analyzes the districts and computes the splits.
  def compute_precinct_splits precinct_number, dists_for_precinct
    smd_districts = dists_for_precinct.reduce([]) {|memo, dist| dist.smd? ? memo | [dist] : memo}
    reg_districts = dists_for_precinct.reduce([]) {|memo, dist| dist.regular? ? memo | [dist.ident] : memo}
    if smd_districts.length == 0
# PrecinctSplit is named: split-<precinct number>. Ident is the precinct number.
      precinct_split_name = "split-#{precinct_number}"
      district_set_ident = "ds-#{precinct_number}"
      @gen.add_precinct_split(precinct_number, precinct_split_name, precinct_number, district_set_ident)
# DistrictSet  is named: ds-<precinct number>
      @gen.add_district_set(district_set_ident, reg_districts)
    else 
      smd_districts.each do
      |a_smd_district|
# PrecinctSplit idend is  split-<precinct number>-<smd name>. Ident is the precinct number.
# DistrictSet  is named: ds-<precinct number>
        precinct_split_ident = "split-#{precinct_number}-#{a_smd_district.name}"
        district_set_ident = "ds-#{precinct_number}-#{a_smd_district.name}"
        @gen.add_precinct_split(precinct_split_ident, precinct_split_ident, precinct_number, district_set_ident)
        @gen.add_district_set(district_set_ident, [a_smd_district.ident]  | reg_districts)
      end    
    end
  end  

# Parse a district line
  def parse_district
    if dist_smd?
      @dist_ident = "dist-#{district_name}"
    elsif !dist_anc?
      @dist_ident = "dist-#{district_name}"
    else # ANC district rows are not real districts, and don't get generated.
      @new_district = nil
      return
    end
    @gen.add_district(@dist_ident, district_name, district_type, district_type_abbrev)
    @new_district = District.new(@dist_ident, district_name, district_type, district_type_abbrev)
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
    @csv[@row][DTYPE].strip
  end
  
  def district_type_abbrev
    @csv[@row][DTYPEABBREV].strip
  end

  def precinct_number
    @csv[@row][PNUMBER].to_i
  end
  
  def precinct_name
    @csv[@row][PNAME]
  end
  
  def dist_smd?
    district_type_abbrev.upcase.eql? "SMD"
  end
  
  def dist_anc?
    district_type_abbrev.upcase.eql? "ANC"
  end  
  
  def dist_regular?
    ! (dist_anc? || dist_smd? )
  end 
end

class District
  attr_accessor :ident, :name, :type, :abbrev
  
  def initialize id, nm, typ, abbr
    @ident = id
    @name = nm
    @type = typ
    @abbrev = abbr
  end
  
  def smd?
    @abbrev.upcase.eql? "SMD"
  end

  def anc?
    @abbrev.upcase.eql? "ANC"
  end  

  def regular?
    ! anc? && ! smd?
  end
end
