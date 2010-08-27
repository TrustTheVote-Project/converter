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
require 'active_support'
require 'active_support/xml_mini'
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
     -s   source format code
          NH -> New Hampshire dump
          DC -> DC Dump
     -o   output destination
"
opts = GetoptLong.new(
      ["-h", "--help", GetoptLong::NO_ARGUMENT],
      ["-s", "--source", GetoptLong::REQUIRED_ARGUMENT],
      ["-o", "--output", GetoptLong::REQUIRED_ARGUMENT])

@source_format = nil

opts.each do |opt, arg|
  case opt
    when "-h"
      puts HELPTEXT
      exit 0
    when "-s"
      @source_format = arg
    when "-o"
      @output_path = Pathname.new(arg)
    end
  end

if ARGV[0].empty?
  puts "Missing file argument (try --help) #{ARGV[0]}"
  exit 0
end

# command line is parsed. Now lets do the work
if @source_format.upcase == "DC"
  gen = DataLayer2.new
elsif @source_format.upcase != "DC"
  gen = DataLayer.new
else
  puts "Invalid format: #{@source_format}"
  exit 0
end

par = NHParser.new(ARGV[-1], gen) if @source_format.upcase == "NH"
par = FLParser.new(ARGV[-1], gen) if @source_format.upcase == "FL"
par = XMLParser.new(ARGV[-1], gen) if @source_format.upcase == "XML"
par = DCParser.new(ARGV[-1], gen) if @source_format.upcase == "DC"

par.parse_file

if @source_format.upcase.eql?("DC") && @output_path.extname.eql?(".yml")
  @output_path.open("w") do |file|
    puts "writing yaml to #{@output_path}"
    YAML.dump(gen.h_file, file)
  end
elsif @source_format.upcase.eql?("DC") && @output_path.extname.eql?(".xml")
  puts "writing XML to #{@output_path}"
  @output_path.open("w")  do |file|
    xml_string = gen.h_file.to_xml({:dasherize=>false, :root => "ttv_object"})
    # Remove type="array" lines and their closing tags
    final_xml_string = ""
    xml_string.each_line { |line|
      if line.include?('type="array"') || line.include?("</precincts>") || line.include?("</districts>") ||
         line.include?("</jurisdictions>") || line.include?("</contests>") || line.include?("</candidates>") ||
         line.include?("</questions>") || line.include?("</elections>")
         # Do not add
      else # Add
        final_xml_string << line
      end
    }
    file.write(final_xml_string)
  end
else
  puts "writing YML (DataLayer Version 1) to #{@output_path}"
  gen.h_file.each do |result|
    @output_path.open("w") do |file|
        YAML.dump(result, file)
    end
  end
end
