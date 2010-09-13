require "date"
require "yaml"
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
#require 'pp'
require 'getoptlong'
require 'pathname'
#require 'flparser'
#require 'nhparser'
require 'dcparser'
#require 'xmlparser'
require 'vaparser'
#require 'active_support'
#require 'active_support/xml_mini'
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
          VA -> Virginia VIP feed
     -t   type code
          jurisdiction - Pull out jurisdictional info (jurisdiction, district, precinct, and split)
          election - Pull out election info (election, contest)
          candidate - Pull out candidate info (candidate, ballot and contest)
     -o   output destination
"
opts = GetoptLong.new(
                      ["-h", "--help", GetoptLong::NO_ARGUMENT],
                      ["-s", "--source", GetoptLong::REQUIRED_ARGUMENT],
                      ["-t", "--type", GetoptLong::REQUIRED_ARGUMENT], 
                      ["-o", "--output", GetoptLong::REQUIRED_ARGUMENT])

@source_format = nil

opts.each do |opt, arg|
  case opt
  when "-h"
    puts HELPTEXT
    exit 0
  when "-t"
    @file_type = case arg.upcase
    when /JUR*/ then :jurisdiction
    when /ELE*/ then :election
    when /CAN*/ then :candidate
    else puts "Invalid file type: #{arg}"
      exit 0
    end
  when "-s"
    @source_format = case arg.upcase
    when /NH*/ then "NH"
    when /VA*/ then "VA"
    when /DC*/ then "DC"
    when /FL*/ then "FL"
    else puts "Invalid file source: #{arg}"
      exit 0
    end
  when "-o"
    @output_path = Pathname.new(arg)
  when "-c"
    @type_code = arg.upcase
  end
end

if ARGV[0].empty?
  puts "Missing file argument (try --help) #{ARGV[0]}"
  exit 0
elsif ARGV.length > 1
  puts "Unknown parameters. Try --help #{ARGV[0..-1]}"
  exit 0
end

#
# Arguments have all been parsed. Based on the arguments, instantiate a DataLayer and a Parser. The Parser knows all about the input
# format, the DataLayer knows about the output format. As we create new versions of the data layer formats we might create new DataLayer classes.
#
case @source_format
when "DC"
  gen = DataLayer2.new(@file_type)
  par = DCParser.new(ARGV[-1], gen)
when "VA"
  gen = DataLayer2.new(@file_type)
  par = VAParser.new(ARGV[-1], gen) 
when "NH"
  gen = DataLayer.new
  par = NHParser.new(ARGV[-1], gen)
when "FL"
  gen = DataLayer2.new(@file_type)
  par = FLParser.new(ARGV[-1], gen)
when "XML"
  gen = DataLayer2.new(@file_type)
  par = XMLParser.new(ARGV[-1], gen)
end

par.parse_file @file_type

case [@source_format, @output_path.extname]
when ["DC", ".yml"]
  @output_path.open("w") do |file|
    puts "writing yaml to #{@output_path}"
    YAML.dump(gen.h_file, file)
  end
when ["VA", ".yml"]
  @output_path.open("w") do |file|
    puts "writing yaml to #{@output_path}"
    YAML.dump(gen.h_file, file)
  end
when ["DC", ".xml"]
  puts "writing XML to #{@output_path}"
  @output_path.open("w")  do |file|
    xml_string = gen.h_file.to_xml({:dasherize=>false, :root => "ttv_object", :skip_types => true })
    # Remove type="array" lines and their closing tags
    final_xml_string = ""
    xml_string.each_line { |line|
      if (line.include?('type="array"') || line.include?("</precincts>") || line.include?("</districts>") ||
        line.include?("</jurisdictions>") || line.include?("</contests>") || line.include?("</candidates>") ||
        line.include?("</questions>") || line.include?("</elections>") || line.include?("</splits>") ||
        line.include?("</district_list")) && false
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
