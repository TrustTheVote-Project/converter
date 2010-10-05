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
require 'ap'
require 'getoptlong'
require 'pathname'
require 'rexml/document'
require "rexml/streamlistener"

#
# Implements a parser for VA formatted election data files
#
class VAParser
  include REXML::StreamListener
  
  def initialize(fname, generator)
    @gen = generator
    @file_name = fname
    @file = File.new(fname)
    @working_on = []
  end
  
  def parse_file ctype
    @ctype = ctype
    if @ctype == :candidate
      # contest_map[ballot_id] = contest_id
      @contest_map = {}
      
      # ballot_map[candidate_id] = ballot_id`
      @ballot_map = {}
      
      # candidate_map[candidate_id] = {:name => name, :party => party}
      @candidate_map = {}
    elsif @ctype == :jurisdiction
      @locality_map = []
    elsif @ctype == :election
      @contest_map = {}
    end
    REXML::Document.parse_stream(@file, self)

  end
  
  def file_start attrs
    tb "file"
    @gen.begin_file @file_name
  end
  
  def file_end
    te "file"
    # For candidate file type, all the generation happens here because the structure
    # of the objects is quite different from the input file.
    if @ctype == :candidate
      generate_candidates
    end
    @gen.end_file
  end
  
  def generate_candidates
    @candidate_map.each do
      |key, value|
        @gen.add_candidate(key, @contest_map[@ballot_map[key]], value[:name], value[:party])
    end
  end
  
  def precinct_start args
    tb "precinct"
    @id = args["id"]
  end
  
  def precinct_end
    te "precinct"
    @gen.add_precinct(@id, @name_tag)
  end
  
  def precinct_split_start attrs
    tb "precinct split"
    working_on :precinct_split
    @precinct_split_id = attrs["id"]
    @precinct_split_districts = []
  end
  
  def precinct_split_end
    te "precinct split"
    @gen.add_district_set(@precinct_split_id, @precinct_split_districts)
    @gen.add_precinct_split(@precinct_split_id, @precinct_split_locality + "-" +  @name_tag, @precinct_id, @precinct_split_id)
  end
  
  def electoral_district_start args
    tb "electoral district"
    @id = args["id"]  
  end
  
  def electoral_district_end
    te "electoral_district: #{@id}, #{@type}"
    @gen.add_district(@id, "#{@name_tag} (#{@id})", @type, "")
# We also collect the id's of all districts that are type==locality so that later we can add locality to a precinct-split name.
    if @type.eql? "LOCALITY"
      @locality_map << @id 
   end
  end
  
  def election_id_start attrs
    tb "election_id"
  end
  
  def election_id_end
    te "election_id"
    @election_id = @text
  end
  
  def precinct_id_start attr
    tb "precinct_id"
  end
  
  def precinct_id_end
    te "precinct_id"
    @precinct_id = @text
  end
  
  def electoral_district_id_start attr
    tb "electoral_district_id"
  end

  def electoral_district_id_end
    te "electoral_district_id"
    @electoral_district_id = @text
# <electoral_district_id> tag inside <precinct_split> 
    if @ctype == :jurisdiction
      @precinct_split_districts << @electoral_district_id
      @precinct_split_locality = @electoral_district_id if @locality_map.include? @electoral_district_id
    end
  end
  
  def source_start attrs
    tb "source"
  end
  
  def contest_start attrs
    tb "contest"
    working_on :contest
    @contest_id = attrs["id"]
    @districts = []
  end
  
  def contest_end
    te "contest, type:#{@type}"
    if @ctype == :election && !@type.eql?("REFERENDUM")
      @gen.add_contest(@contest_id, @election_id, @electoral_district_id, @office_name, @ballot_placement)
    end
  end
  
  def ballot_id_start attrs
    tb "ballot_id"
  end
  
  def ballot_id_end
    te "ballot_id"
    @contest_map[@text] = @contest_id
  end
  
  def ballot_start attrs
    tb "ballot"
    @ballot_id = attrs["id"]
  end
  
  def ballot_end
    te "ballot"
  end

  def candidate_id_start attrs
    tb "candidate_id"
  end
  
  def candidate_id_end
    te "candidate_id"
    @ballot_map[@text] = @ballot_id
  end
  
  def candidate_start attrs
    tb "candidate"
    @candidate_id = attrs["id"]
  end
  
  def candidate_end
    te "candidate"
    @candidate_map[@candidate_id] = {:name => @name_tag, :party => @candidate_party}
  end
  
  def party_start attrs
    tb "party"
  end
  
  def party_end
    te "party"
    @candidate_party = @text.gsub(/\s/, "")

  end
  
  def source_end
    te "source"
  end
  
  def office_start attrs
    tb "office"
  end
  
  def office_end
    te "office"
    @office_name = @text
  end
  
  
  def election_start args
    @election_ident = args["id"]
  end
  
  
  def election_end
    te "election"
    @gen.add_election(@election_ident, @date_tag, @election_type)
  end
  
  def locality_id_start arg
    tb "locality_id"
  end
  
  def locality_id_end
    te "locality_id"
    @locality_id = @text
  end
  
  def contest_begin attrs
    @contest_ident = attrs["id"]
    @districts = []
  end
  
  def type_start args    
    tb "type"
  end
  
  def type_end
    te "type"
    @type = @text
  end
  
  def name_start args  
    tb "name"
  end
  
  def name_end
    te "name"
    @name_tag = @text
  end
  
  def electoral_district_id_start attrs
    tb "electoral_district_id"
  end
  
  def electoral_district_id
    @electoral_district_id = @text
  end
  
  def ballot_placement_start attrs
    tb "ballot_placement"
  end
  
  def ballot_placement_end
    te "ballot_placement"
    @ballot_placement = @text
  end

  
  def date_start args
    te "date"
  end
  
  def date_end
    te "date"
    @date_tag = @text
  end
  
  def election_type_start args
    tb "election_type"
  end
  
  def election_type_end
    @election_type = @text
  end
  
  def date_end
    te "date"
    @date_tag = @text
  end
  
  def working_on new_state
    @working_on << new_state
  end
  
  def tb string
     puts "< begin #{string}"
  end
  
  def te string
     puts "> end #{string}"
  end
  
  #
  # Following are the Callbacks for the REXML Stream Parsing
  #
  
  # Plain text found. Ignore white space
  def text text_found
    return if text_found.strip.empty?
    @text = text_found.lstrip.rstrip
  end
  
  def tag_start(name, attrs)
    case name
      
    when "source"
      source_start attrs
    when "election"
      election_start attrs
    when "election_type"
      election_type_start attrs
    when "election_id"
      election_id_start attrs
    when "electoral_district_id"
      electoral_district_id_start attrs
    when "office"
      office_start attrs
    when "ballot_placement"
      ballot_placement_start attrs
    when "date"
      date_start attrs
    when "contest"
      contest_start attrs
    when "candidate"
      candidate_start attrs
    when "precinct"
      precinct_start attrs
    when "electoral_district"
      electoral_district_start attrs
    when "precinct_split"
      precinct_split_start attrs
    when "precinct_id"
      precinct_id_start attrs
    when "vip_object"
      file_start attrs
    when "name"
      name_start attrs
    when "locality_id"
      locality_id_start attrs
    when "electoral_district_id"
      electoral_district_id_start attrs
    when "type"
      type_start attrs
    when "ballot"
      ballot_start attrs
    when "candidate_id"
      candidate_id_start attrs
    when "party"
      party_start attrs
    when "ballot_id"
      ballot_id_start attrs
    end
  end
  
  def tag_end(name)
    case name
      
    when "source"
      source_end
    when "contest"
      contest_end
    when "electoral_district_id"
      electoral_district_id_end
    when "office"
      office_end
    when "ballot_placement"
      ballot_placement_end
    when "election_id"
      election_id_end
    when "election"
      election_end
    when "candidate"
      candidate_end
    when "election_type"
      election_type_end
    when "date"
      date_end
    when "precinct"
      precinct_end
    when "electoral_district"
      electoral_district_end
    when "precinct_split"
      precinct_split_end
    when "precinct_id"
      precinct_id_end
    when "vip_object"
      file_end
    when "name"
      name_end
    when "locality_id"
      locality_id_end
    when "electoral_district_id"
      electoral_district_id_end
    when "type"
      type_end
    when "ballot"
      ballot_end
    when "candidate_id"
      candidate_id_end
    when "party"
      party_end
    when "ballot_id"
      ballot_id_end
    end
  end
end 
