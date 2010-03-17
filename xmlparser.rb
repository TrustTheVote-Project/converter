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
require 'rexml/document'
include REXML

#
# Implements a parser for XML formatted election data files
#
class XMLParser

  attr_reader :file

  def initialize(fname, generator)
    @file = Document.new(File.new(fname))
    @gen = generator
    @districts = {} # ID => name
    @contests = {} # Cont. ID => Dist. ID 
  end

  def parse_file
    @gen.begin_file

    start_election

    parse_district_names
    parse_contest_district
    
    parse_precincts
    parse_contests
    
    @gen.end_ballot
    @gen.end_file
  end
  
  def start_election
    @gen.start_ballot(@file.elements["EDX/County/Election"].attributes["name"])
  end
  
  def parse_district_names
    @file.elements.each("EDX/County/Election/Districts/District") { |district|
      @districts[district.attributes["id"]] = district.attributes["name"]
    }
  end
  
  # Generate a hash table of election/district mappings
  def parse_contest_district
    @file.elements.each("EDX/County/Election/DistrictContests/DistrictContest") { |dc|
      @contests[dc.attributes["contest"]] = dc.attributes["district"]
    }
  end
  
  # Convert district ID to district name
  def district_name(district)
    @districts[district.to_s]
  end
  
  # Convert contest ID to district 
  # Should be seeded by running parse_contest_district 
  def contest_district(contest)
    @contests[contest]
  end

  def parse_precincts
    @file.elements.each("EDX/County/Election/Precincts/Precinct") { |precinct|
      parse_splits(precinct)
    }
  end
  
  def parse_splits(precinct)
    if precinct.elements["Splits/Split"].nil?
      if precinct.attributes["displayOrder"].nil?
        @gen.start_precinct(precinct.attributes["name"])
      else
        @gen.start_precinct(precinct.attributes["name"], precinct.attributes["displayOrder"].to_i)
      end
      parse_districts(precinct)
      @gen.end_precinct
    else
      precinct.elements.each("Splits/Split") { |split|
        if split.attributes["displayOrder"].nil?
          @gen.start_precinct(precinct.attributes["name"] + "." + 
                              split.attributes["name"])
        else
          @gen.start_precinct(precinct.attributes["name"] + "." + 
                              split.attributes["name"],
                              split.attributes["displayOrder"].to_i)
        end
        parse_districts(split)
        @gen.end_precinct
      }
    end
    
  end
  
  def parse_districts(split)
    split.elements.each("DistrictPrecinctSplits/DistrictPrecinctSplit") { |district|
      @gen.add_district(district_name(district.attributes["district"]))
    }
  end
  
  def parse_contests
    @file.elements.each("EDX/County/Election/Contests/Contest") { |contest|
      if contest.attributes["displayOrder"].nil?
        @gen.start_contest(contest.attributes["name"])
        #                   "Vote for only " + contest.attributes["maxVotes"].to_s
      else
        @gen.start_contest(contest.attributes["name"], contest.attributes["displayOrder"].to_i)
      end
      
      # Send district for contest
      @gen.contest_district(district_name(contest_district(contest.attributes["id"])))
      
      parse_candidates(contest)
      @gen.end_contest
    }
  end
  
  def parse_candidates(contest)
    contest.elements.each("Choice") { |candidate|
      if candidate.attributes["displayOrder"].nil?
        @gen.add_candidate(candidate.attributes["name"], "Nonpartisan")
      else
        @gen.add_candidate(candidate.attributes["name"], "Nonpartisan",
                           candidate.attributes["displayOrder"].to_i)
      end
    }
  end
  
end