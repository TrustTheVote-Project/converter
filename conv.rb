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
require 'pp'
require 'getoptlong'
require 'pathname'
require 'flparser'
require 'nhparser'
require 'dcparser'
require 'xmlparser'
require 'data_layer'
require 'data_layer_v2'

#
# Main Program: Parse the command line and do the work
#
HELPTEXT = "TTV File Coverter.
Converts text file with ballot info into TTV standard data layer
Usage:
    conv [-options] file

 Options:
     -h   display help text
     -f   format code
          NH -> New Hampshire dump
          DC -> DC Dump
     -o   optional destination folder
"
opts = GetoptLong.new(
      ["-h", "--help", GetoptLong::NO_ARGUMENT],
      ["-f", "--format", GetoptLong::REQUIRED_ARGUMENT],
      ["-o", "--output", GetoptLong::REQUIRED_ARGUMENT])
@format = nil
@dir = Pathname.new(".")
opts.each do |opt, arg|
  case opt
    when "-h"
      puts HELPTEXT
      exit 0
    when "-f"
      @format = arg
      break
    when "-o"
      @dir = Pathname.new(arg)
      puts "***** #{@dir}"
      if @dir.exist? && !@dir.directory?
        puts "#{arg} doesn't seem to be a directory" unless @dir.directory?
        exit 0
      end
    end
  end

if ARGV[0].empty?
  puts "Missing file argument (try --help) #{ARGV[0]}"
  exit 0
end

# command line is parsed. Now lets do the work
if @format.upcase == "DC"
  gen = DataLayer2.new
elsif @format.upcase != "DC"
  gen = DataLayer.new
else
  puts "Invalid format: #{@format}"
  exit 0
end
  
par = NHParser.new(ARGV[0], gen) if @format.upcase == "NH"
par = FLParser.new(ARGV[0], gen) if @format.upcase == "FL"
par = XMLParser.new(ARGV[0], gen) if @format.upcase == "XML"
par = DCParser.new(ARGV[0], gen) if @format.upcase == "DC"

par.parse_file

@dir.mkdir unless @dir.directory?
@dir = @dir.realpath
i = 0

gen.h_file.each do |result|
  @file = @dir + "file.yml"
  @file.open("w") do |file|
    if @format.upcase == "DC"
      YAML.dump(result["precincts"], file)
      YAML.dump(result["splits"], file)
      YAML.dump(result["district_sets"], file)
      YAML.dump(result["districts"], file)
    else
      YAML.dump(result, file)
    end
  end
end
