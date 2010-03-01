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

#
# Implements a simple top-down parser for the New Hampshire formatted input file.  @line is the current line, and @lookahead is the next line.
# Some of the syntax requires us to know what the next line looks like. At interesting points in the parsing, we call Generator who then 
# uses what the parser knows to build up what is to be written out.
class Parser
  
  def initialize(fname, generator)
    @file = File.open(fname)
    @lookahead = ""
    @line = ""
    @gen = generator
  end
  
  def get_line
    @line = @lookahead
    if !@file.eof?
      @lookahead = @file.readline.chomp
    else
      @lookahead = ""
    end
  end
  
  #
  # Parse the whole file. A file consists of a series of ballots. The two get_lines prime the two key
  # parser variables, @line and @lookahead.
  #
  def parse_file()
    @gen.begin_file
    get_line
    get_line
    if @lookahead != ""
      parse_ballots()
    end
    @gen.end_file
  end
  
  #
  # Parse a series of ballots. The last ballot occurs when we see the end-of-file.
  # 
  def parse_ballots
    while !@file.eof?
      parse_ballot
    end
  end
  
  #
  # Parse a single ballot. Always start with the string "General Election Ballot". The first line after that is 
  # the town name. Skip a line and then we expect a series of contests.
  #
  def parse_ballot
    raise "unexpected start of section" unless @line == "General Election Ballot"
    get_line
    town = @line
    puts "parsed town: #{town}"
    get_line
    get_line
    @gen.start_ballot(town)
    parse_contests
    @gen.end_ballot
  end
  
  #
  # Contests are one after the other, until we hit the start of the next ballot.
  #
  def parse_contests
    while @line != "General Election Ballot" && !@file.eof?
      @contest = @line.chomp
      get_line
      @rule = @line.chop.lstrip
      get_line
      @gen.start_contest(@contest, @rule)
      parse_candidates()
      @gen.end_contest
    end
  end
  
  #
  # Parse one or more candidates for this contest. Next contest starts when non-indented line is seen.
  #
  def parse_candidates()
    while line_indented?
      parse_candidate
    end
  end
  
  def line_indented?
    @line[0] == 32
  end
  
  def parse_candidate
    name = @line.chomp.lstrip
    get_line
    party = @line.chomp.lstrip
    get_line
    @gen.add_candidate(name, party)
  end
end
